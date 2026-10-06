import { findGreen, getJson } from "../shared/green.js";
import type { HookEvent, HookResponse } from "../shared/types.js";

// Config comes from hook_details in Terraform; progress rides back in hookDetails between rounds.
interface Details {
  testUrl: string;
  testHeader?: string; // "name:value" when test_routing = "header"
  rounds?: number;
  requestsPerRound?: number;
  round?: number;
  ok?: number;
  errors?: number;
  lastError?: string;
  waits?: number;
}

const ROUND_DELAY_SECONDS = 15;
// ECS invokes this stage when the test shift starts; the listener rule takes a few seconds
// to reach green. Until green answers, wait instead of judging blue's responses.
const SHIFT_DELAY_SECONDS = 5;
const MAX_SHIFT_WAITS = 8;

// TEST_TRAFFIC_SHIFT: send test traffic in rounds; any error fails the deployment and ECS rolls back.
export const handler = async (event: HookEvent<Details>): Promise<HookResponse<Details>> => {
  console.log(JSON.stringify({ msg: "hook invoked", event }));
  const details = event.hookDetails!;
  const { targetServiceRevisionArn, testTrafficWeights } = event.executionDetails;

  // ECS re-invokes this stage while rolling back; never block a rollback.
  if (testTrafficWeights[targetServiceRevisionArn] === 0) {
    console.log(JSON.stringify({ msg: "rollback re-invocation", hookStatus: "SUCCEEDED" }));
    return { hookStatus: "SUCCEEDED" };
  }

  const rounds = details.rounds ?? 4;
  const perRound = details.requestsPerRound ?? 10;
  const round = (details.round ?? 0) + 1;
  let ok = details.ok ?? 0;
  let errors = details.errors ?? 0;
  let lastError = details.lastError;
  const waits = details.waits ?? 0;

  const { expectedVersion } = await findGreen(event);
  const headers: Record<string, string> = {};
  if (details.testHeader) {
    const [name, value] = details.testHeader.split(":");
    headers[name] = value;
  }

  let fromGreen = 0;
  for (let i = 0; i < perRound; i++) {
    let res = await getJson(`${details.testUrl}/api/bounties`, headers);
    // A lone timeout can't be attributed to green (the connection may have hit blue or a
    // draining task). Retry once; two in a row count as an error.
    if (res.status === 0) res = await getJson(`${details.testUrl}/api/bounties`, headers);
    if (res.status !== 0 && res.version !== expectedVersion) continue; // blue answered: shift not done yet
    fromGreen++;
    if (res.status === 200) {
      ok++;
    } else {
      errors++;
      lastError = `${res.status} ${res.version ?? ""} ${res.error ?? ""}`.trim();
    }
  }

  if (fromGreen === 0) {
    if (waits >= MAX_SHIFT_WAITS) {
      console.log(JSON.stringify({ msg: "validation failed: test traffic never reached green", expectedVersion, waits, hookStatus: "FAILED" }));
      return { hookStatus: "FAILED" };
    }
    console.log(JSON.stringify({ msg: "waiting for test traffic to reach green", expectedVersion, waits: waits + 1, hookStatus: "IN_PROGRESS" }));
    return { hookStatus: "IN_PROGRESS", callBackDelay: SHIFT_DELAY_SECONDS, hookDetails: { ...details, waits: waits + 1 } };
  }

  const progress = { round, rounds, ok, errors, expectedVersion, lastError };

  if (errors > 0) {
    console.log(JSON.stringify({ msg: "validation failed", ...progress, hookStatus: "FAILED" }));
    return { hookStatus: "FAILED" };
  }
  if (round >= rounds) {
    console.log(JSON.stringify({ msg: "validation passed", ...progress, hookStatus: "SUCCEEDED" }));
    return { hookStatus: "SUCCEEDED" };
  }

  console.log(JSON.stringify({ msg: "validation round", ...progress, hookStatus: "IN_PROGRESS" }));
  return {
    hookStatus: "IN_PROGRESS",
    callBackDelay: ROUND_DELAY_SECONDS,
    hookDetails: { ...details, round, ok, errors, lastError },
  };
};
