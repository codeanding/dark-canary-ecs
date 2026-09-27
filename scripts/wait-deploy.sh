#!/usr/bin/env bash
# Polls the latest service deployment until it finishes. Exit 0 only on SUCCESSFUL.
set -euo pipefail
source "$(dirname "$0")/env.sh"

while true; do
  STATE="$("$ROOT/scripts/status.sh")"
  STATUS="$(jq -r .status <<<"$STATE")"
  echo "$(date +%T)  $STATUS  $(jq -r '.stage // "-"' <<<"$STATE")"
  case "$STATUS" in
    SUCCESSFUL) exit 0 ;;
    ROLLBACK_SUCCESSFUL | ROLLBACK_FAILED | STOPPED) exit 1 ;;
  esac
  sleep 15
done
