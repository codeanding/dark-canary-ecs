#!/usr/bin/env bash
# Tears everything down: Terraform stack plus the task definition revisions deploy.sh registered.
set -euo pipefail
source "$(dirname "$0")/env.sh"

terraform -chdir="$ROOT/infra" destroy

for arn in $(aws ecs list-task-definitions --family-prefix dark-canary --status ACTIVE \
  --query 'taskDefinitionArns[]' --output text); do
  aws ecs deregister-task-definition --task-definition "$arn" >/dev/null
  echo "deregistered $arn"
done
