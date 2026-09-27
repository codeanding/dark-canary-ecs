#!/usr/bin/env bash
# Shows the latest service deployment, its lifecycle stage and hook status.
set -euo pipefail
source "$(dirname "$0")/env.sh"

CLUSTER="$(tf_out cluster_name)"
SERVICE="$(tf_out service_name)"

ARN="$(aws ecs list-service-deployments --cluster "$CLUSTER" --service "$SERVICE" \
  --query 'serviceDeployments[0].serviceDeploymentArn' --output text)"

aws ecs describe-service-deployments --service-deployment-arns "$ARN" \
  --query 'serviceDeployments[0].{status:status,stage:lifecycleStage,reason:statusReason,rollback:rollback,hooks:lifecycleHookDetails}' \
  --output json
