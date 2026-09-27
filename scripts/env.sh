# Sourced by every script. Override with AWS_PROFILE / AWS_REGION in your shell if needed.
export AWS_PROFILE="${AWS_PROFILE:-codeanding}"
export AWS_REGION="${AWS_REGION:-us-west-2}"
export AWS_PAGER=""

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

tf_out() { terraform -chdir="$ROOT/infra" output -raw "$1"; }
