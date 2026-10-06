import { findGreen, getJson } from "../shared/green.js";
import type { HookEvent, HookResponse } from "../shared/types.js";

const DEFAULT_APP_PORT = 3000;

// POST_SCALE_UP: green has no traffic yet. Call each task and check it runs the new version.
export const handler = async (event: HookEvent): Promise<HookResponse> => {
  console.log(JSON.stringify({ msg: "hook invoked", event }));

  const appPort = Number(event.hookDetails?.appPort ?? DEFAULT_APP_PORT);
  const green = await findGreen(event);
  if (green.taskIps.length === 0) {
    console.log(JSON.stringify({ msg: "no green tasks found", hookStatus: "FAILED" }));
    return { hookStatus: "FAILED" };
  }

  const checks = await Promise.all(
    green.taskIps.map(async (ip) => ({ ip, ...(await getJson(`http://${ip}:${appPort}/version`)) })),
  );
  const healthy = checks.every((c) => c.status === 200 && c.version === green.expectedVersion);
  const hookStatus = healthy ? "SUCCEEDED" : "FAILED";

  console.log(JSON.stringify({ msg: "smoke check", expectedVersion: green.expectedVersion, checks, hookStatus }));
  return { hookStatus };
};
