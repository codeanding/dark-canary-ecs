#!/usr/bin/env bash
# Usage: scripts/build-push.sh <tag>   e.g. v1, v2-broken, v2-fixed
set -euo pipefail
source "$(dirname "$0")/env.sh"

TAG="${1:?usage: build-push.sh <tag>}"
REPO="$(tf_out ecr_repository_url)"

# Drop any stale ECR token first: the macOS keychain helper refuses to overwrite an existing entry.
for r in "${REPO%%/*}" "https://${REPO%%/*}"; do docker logout "$r" >/dev/null 2>&1 || true; done
aws ecr get-login-password | docker login --username AWS --password-stdin "${REPO%%/*}"
docker build --platform linux/arm64 --build-arg APP_VERSION="$TAG" -t "$REPO:$TAG" "$ROOT/app"
docker push "$REPO:$TAG"
