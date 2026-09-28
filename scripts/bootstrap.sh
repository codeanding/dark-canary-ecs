#!/usr/bin/env bash
# First-time setup from a clean account: ECR first, push v1, then the rest of the stack.
set -euo pipefail
source "$(dirname "$0")/env.sh"

(cd "$ROOT/hooks" && npm install --silent && npm run build)

terraform -chdir="$ROOT/infra" init -upgrade
terraform -chdir="$ROOT/infra" apply -target=aws_ecr_repository.app
# All three releases up front: deploy.sh only registers task definitions, it never builds.
for tag in v1 v2-broken v2-fixed; do "$ROOT/scripts/build-push.sh" "$tag"; done
terraform -chdir="$ROOT/infra" apply

# On service creation ECS registers the first task in the alternate (green) target group but
# leaves the production rule on blue, so prod answers 503. One real deployment normalizes it.
aws ecs wait services-stable --cluster "$(tf_out cluster_name)" --services "$(tf_out service_name)"
"$ROOT/scripts/deploy.sh" v1
AUTO_CONTINUE=1 "$ROOT/scripts/wait-deploy.sh"

echo
echo "prod: $(tf_out prod_url)/version"
echo "test: $(tf_out test_url)"
