// Deployment helpers the AWS CLI may not have yet (ContinueServiceDeployment, hook details).
// Usage: node scripts/ecs.mjs arn | status | continue [rollback] | circuit-breaker
import { createRequire } from "node:module";

// Reuses the AWS SDK installed in hooks/ (no separate package.json for scripts).
const require = createRequire(new URL("../hooks/package.json", import.meta.url));
const {
  ECSClient,
  ListServiceDeploymentsCommand,
  DescribeServiceDeploymentsCommand,
  ContinueServiceDeploymentCommand,
  DescribeServicesCommand,
  UpdateServiceCommand,
} = require("@aws-sdk/client-ecs");

const USAGE = "usage: node scripts/ecs.mjs arn | status | continue [rollback] | circuit-breaker";
const COMMANDS = ["arn", "status", "continue", "circuit-breaker"];

const [, , command, arg] = process.argv;
const { CLUSTER, SERVICE } = process.env;
const ecs = new ECSClient({});

// The provider (6.66) can't set the circuit breaker threshold yet. UpdateService replaces the
// whole deploymentConfiguration, so merge into the current one to keep the strategy and hooks.
async function configureCircuitBreaker() {
  const { services: [svc] } = await ecs.send(new DescribeServicesCommand({ cluster: CLUSTER, services: [SERVICE] }));
  if (!svc) throw new Error(`service ${SERVICE} not found in cluster ${CLUSTER}`);
  const current = svc.deploymentConfiguration;
  const deploymentCircuitBreaker = {
    ...current.deploymentCircuitBreaker,
    enable: true,
    rollback: true,
    resetOnHealthyTask: false, // cumulative: every failed task counts
    thresholdConfiguration: { type: "COUNT", value: 2 }, // default would be 3 (50% of 1, clamped to 3)
  };
  await ecs.send(new UpdateServiceCommand({
    cluster: CLUSTER,
    service: SERVICE,
    deploymentConfiguration: { ...current, deploymentCircuitBreaker },
  }));
  console.log(JSON.stringify({ deploymentCircuitBreaker }));
}

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

async function main() {
  if (!COMMANDS.includes(command)) {
    console.error(USAGE);
    process.exit(2);
  }
  if (!CLUSTER || !SERVICE) throw new Error("CLUSTER and SERVICE must be set (the wrapper scripts do it)");

  if (command === "circuit-breaker") return configureCircuitBreaker();

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
  } else {
    const paused = hooks.find((h) => h.type === "PAUSE" && h.status === "AWAITING_ACTION");
    if (!paused) throw new Error(`no paused hook to continue (deployment ${d.status}, stage ${d.lifecycleStage})`);
    const action = arg === "rollback" ? "ROLLBACK" : "CONTINUE";
    await ecs.send(
      new ContinueServiceDeploymentCommand({ serviceDeploymentArn: d.serviceDeploymentArn, hookId: paused.hookId, action }),
    );
    console.log(`${action} sent for hook ${paused.hookId}`);
  }
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
