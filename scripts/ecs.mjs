// Deployment helpers the AWS CLI may not have yet (ContinueServiceDeployment, hook details).
// Usage: node scripts/ecs.mjs arn | status | continue [rollback]
// Reads AWS_PROFILE / AWS_REGION from the environment (set by scripts/env.sh).
import { createRequire } from "node:module";

const require = createRequire(new URL("../hooks/package.json", import.meta.url));
const {
  ECSClient,
  ListServiceDeploymentsCommand,
  DescribeServiceDeploymentsCommand,
  ContinueServiceDeploymentCommand,
} = require("@aws-sdk/client-ecs");

const [, , command, arg] = process.argv;
const { CLUSTER, SERVICE } = process.env;
const ecs = new ECSClient({});

async function latestDeployment() {
  const { serviceDeployments = [] } = await ecs.send(
    new ListServiceDeploymentsCommand({ cluster: CLUSTER, service: SERVICE, maxResults: 1 }),
  );
  if (!serviceDeployments[0]) throw new Error("no deployments yet");
  const { serviceDeployments: [d] } = await ecs.send(
    new DescribeServiceDeploymentsCommand({ serviceDeploymentArns: [serviceDeployments[0].serviceDeploymentArn] }),
  );
  return d;
}

const d = await latestDeployment();
const hooks = (d.lifecycleHookDetails ?? []).map((h) => ({
  hookId: h.hookId,
  type: h.targetType,
  status: h.status,
  target: h.targetArn?.split(":").pop(),
}));

if (command === "arn") {
  console.log(d.serviceDeploymentArn);
} else if (command === "status") {
  console.log(JSON.stringify({ status: d.status, stage: d.lifecycleStage ?? null, reason: d.statusReason ?? null, hooks }, null, 2));
} else if (command === "continue") {
  const paused = hooks.find((h) => h.type === "PAUSE" && h.status === "AWAITING_ACTION");
  if (!paused) {
    console.error(`No paused hook to continue (deployment ${d.status}, stage ${d.lifecycleStage}).`);
    process.exit(1);
  }
  const action = arg === "rollback" ? "ROLLBACK" : "CONTINUE";
  await ecs.send(
    new ContinueServiceDeploymentCommand({ serviceDeploymentArn: d.serviceDeploymentArn, hookId: paused.hookId, action }),
  );
  console.log(`${action} sent for hook ${paused.hookId}`);
} else {
  console.error("usage: node scripts/ecs.mjs arn | status | continue [rollback]");
  process.exit(2);
}
