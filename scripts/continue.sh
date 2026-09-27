#!/usr/bin/env bash
# Resumes a deployment held by the PAUSE hook. Usage: scripts/continue.sh [rollback]
set -euo pipefail
source "$(dirname "$0")/env.sh"

CLUSTER="$(tf_out cluster_name)" SERVICE="$(tf_out service_name)" node "$ROOT/scripts/ecs.mjs" continue "${1:-}"
