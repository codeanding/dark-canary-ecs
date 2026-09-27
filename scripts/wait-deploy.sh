#!/usr/bin/env bash
# Polls the latest service deployment until it finishes. Exit 0 only on SUCCESSFUL.
# AUTO_CONTINUE=1 resumes the PAUSE hook automatically (used by bootstrap, not in the demo).
set -euo pipefail
source "$(dirname "$0")/env.sh"

while true; do
  STATE="$("$ROOT/scripts/status.sh")"
  STATUS="$(jq -r .status <<<"$STATE")"
  echo "$(date +%T)  $STATUS  $(jq -r '.stage // "-"' <<<"$STATE")  $(jq -c '[.hooks[] | "\(.type):\(.status)"]' <<<"$STATE")"
  case "$STATUS" in
    SUCCESSFUL) exit 0 ;;
    ROLLBACK_SUCCESSFUL | ROLLBACK_FAILED | STOPPED) exit 1 ;;
  esac
  if [[ "${AUTO_CONTINUE:-0}" == 1 ]] && jq -e '.hooks[] | select(.type == "PAUSE" and .status == "AWAITING_ACTION")' <<<"$STATE" >/dev/null; then
    "$ROOT/scripts/continue.sh"
  fi
  sleep 15
done
