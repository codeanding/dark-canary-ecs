#!/usr/bin/env bash
# Usage: scripts/set-routing.sh header|port   (header is the default)
# Switches how test traffic reaches green, then redeploys the current version
# (a new test rule starts on blue).
set -euo pipefail
source "$(dirname "$0")/env.sh"

MODE="${1:?usage: set-routing.sh port|header}"
[[ "$MODE" == header || "$MODE" == port ]] || { echo "usage: set-routing.sh port|header" >&2; exit 2; }
TFVARS="$ROOT/infra/terraform.tfvars"

grep -v '^test_routing' "$TFVARS" > "$TFVARS.tmp" || true
echo "test_routing = \"$MODE\"" >> "$TFVARS.tmp"
mv "$TFVARS.tmp" "$TFVARS"

terraform -chdir="$ROOT/infra" apply
# terraform apply drops the circuit breaker threshold; set it again.
CLUSTER="$(tf_out cluster_name)" SERVICE="$(tf_out service_name)" node "$ROOT/scripts/ecs.mjs" circuit-breaker

CURRENT_TAG="$(aws ecs describe-task-definition --task-definition "$(aws ecs describe-services \
  --cluster "$(tf_out cluster_name)" --services "$(tf_out service_name)" \
  --query 'services[0].taskDefinition' --output text)" \
  --query 'taskDefinition.containerDefinitions[0].image' --output text)"
"$ROOT/scripts/deploy.sh" "${CURRENT_TAG##*:}"
AUTO_CONTINUE=1 "$ROOT/scripts/wait-deploy.sh"

echo "test traffic: $(tf_out test_url)"
