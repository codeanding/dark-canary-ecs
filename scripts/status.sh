#!/usr/bin/env bash
# Shows the latest service deployment, its lifecycle stage and hook status.
set -euo pipefail
source "$(dirname "$0")/env.sh"

CLUSTER="$(tf_out cluster_name)" SERVICE="$(tf_out service_name)" node "$ROOT/scripts/ecs.mjs" status
