# shellcheck shell=bash
# Sourced by every script. Override with AWS_PROFILE / AWS_REGION in your shell if needed.
export AWS_PROFILE="${AWS_PROFILE:-codeanding}"
export AWS_REGION="${AWS_REGION:-us-west-2}"
export AWS_PAGER=""
export TF_VAR_aws_profile="$AWS_PROFILE" TF_VAR_aws_region="$AWS_REGION"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for cmd in aws terraform node pnpm jq docker; do
  command -v "$cmd" >/dev/null || { echo "missing dependency: $cmd" >&2; exit 1; }
done

tf_out() { terraform -chdir="$ROOT/infra" output -raw "$1"; }
