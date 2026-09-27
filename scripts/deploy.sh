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

aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --task-definition "$NEW_ARN" \
  --query 'service.deployments[0].{id:id,status:status,taskDefinition:taskDefinition}' --output table

echo "Deploying $TAG → $NEW_ARN"
echo "Watch it with: scripts/status.sh"
