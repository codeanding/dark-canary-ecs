import {
  DescribeTaskDefinitionCommand,
  DescribeTasksCommand,
  ECSClient,
  ListTasksCommand,
} from "@aws-sdk/client-ecs";
import type { HookEvent } from "./types.js";

const ecs = new ECSClient({});

export interface GreenRevision {
  expectedVersion: string; // image tag of the green revision, e.g. "v2-broken"
  taskIps: string[];
}

// Finds the tasks of the revision being deployed. Native blue/green starts them with
// startedBy = "ecs-svc/<service revision id>", and that id ends targetServiceRevisionArn.
export async function findGreen(event: HookEvent<unknown>): Promise<GreenRevision> {
  const { serviceArn, targetServiceRevisionArn } = event.executionDetails;
  const cluster = serviceArn.split("/")[1];
  const revisionId = targetServiceRevisionArn.split("/").pop();

  const { taskArns = [] } = await ecs.send(
    new ListTasksCommand({ cluster, startedBy: `ecs-svc/${revisionId}`, desiredStatus: "RUNNING" }),
  );
  if (taskArns.length === 0) return { expectedVersion: "unknown", taskIps: [] };

  const { tasks = [] } = await ecs.send(new DescribeTasksCommand({ cluster, tasks: taskArns }));
  const taskIps = tasks
    .flatMap((t) => t.attachments ?? [])
    .flatMap((a) => a.details ?? [])
    .filter((d) => d.name === "privateIPv4Address" && d.value)
    .map((d) => d.value!);

  const { taskDefinition } = await ecs.send(
    new DescribeTaskDefinitionCommand({ taskDefinition: tasks[0].taskDefinitionArn }),
  );
  const image = taskDefinition?.containerDefinitions?.[0]?.image ?? "";
  const expectedVersion = image.split(":").pop() ?? "unknown";

  return { expectedVersion, taskIps };
}

export async function getJson(url: string, headers: Record<string, string> = {}) {
  try {
    const res = await fetch(url, { headers, signal: AbortSignal.timeout(3000) });
    const body = (await res.json().catch(() => null)) as { version?: string; error?: string } | null;
    return { status: res.status, version: body?.version, error: body?.error };
  } catch (err) {
    return { status: 0, version: undefined, error: (err as Error).message };
  }
}
