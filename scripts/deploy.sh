#!/usr/bin/env bash
# Usage: scripts/deploy.sh <tag>
# Registers a task definition revision with the new image and starts a blue/green deployment.
set -euo pipefail
source "$(dirname "$0")/env.sh"

TAG="${1:?usage: deploy.sh <tag>}"
CLUSTER="$(tf_out cluster_name)"
SERVICE="$(tf_out service_name)"
REPO="$(tf_out ecr_repository_url)"

CURRENT="$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
  --query 'services[0].taskDefinition' --output text)"

NEW_DEF="$(aws ecs describe-task-definition --task-definition "$CURRENT" --query taskDefinition \
  | jq --arg img "$REPO:$TAG" '
      .containerDefinitions[0].image = $img
      | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities,
            .registeredAt, .registeredBy, .deregisteredAt)')"

NEW_ARN="$(aws ecs register-task-definition --cli-input-json "$NEW_DEF" \
  --query 'taskDefinition.taskDefinitionArn' --output text)"

ecs_node() { CLUSTER="$CLUSTER" SERVICE="$SERVICE" node "$ROOT/scripts/ecs.mjs" "$@"; }
PREVIOUS="$(ecs_node arn 2>/dev/null || true)"

aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --task-definition "$NEW_ARN" \
  --query 'service.deployments[0].{id:id,status:status,taskDefinition:taskDefinition}' --output table

# ECS lists the new deployment a few seconds later.
for _ in $(seq 60); do
  [[ "$(ecs_node arn)" != "$PREVIOUS" ]] && break
  sleep 2
done
[[ "$(ecs_node arn)" != "$PREVIOUS" ]] || { echo "ECS did not start a new deployment after 2 minutes" >&2; exit 1; }

echo "Deploying $TAG → $NEW_ARN"
echo "Watch it with: scripts/status.sh"
