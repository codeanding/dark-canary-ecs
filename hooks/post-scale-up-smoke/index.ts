import type { HookEvent, HookResponse } from "../shared/types.js";

// Checkpoint 1: log the real event (slide material) and let the deployment continue.
// Checkpoint 3 replaces this with the smoke check against the green task.
export const handler = async (event: HookEvent): Promise<HookResponse> => {
  console.log(JSON.stringify({ msg: "hook invoked", event }));
  return { hookStatus: "SUCCEEDED" };
};
