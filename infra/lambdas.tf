locals {
  # Checkpoint 1: one hook that logs the event and always succeeds.
  hooks = {
    post-scale-up-smoke = {
      stages = ["POST_SCALE_UP"]
    }
  }
}

data "archive_file" "hook" {
  for_each = local.hooks

  type        = "zip"
  source_dir  = "${path.module}/../hooks/dist/${each.key}"
  output_path = "${path.module}/.build/${each.key}.zip"
}

resource "aws_cloudwatch_log_group" "hook" {
  for_each = local.hooks

  name              = "/aws/lambda/${var.project_name}-${each.key}"
  retention_in_days = 7
}

resource "aws_lambda_function" "hook" {
  for_each = local.hooks

  function_name    = "${var.project_name}-${each.key}"
  role             = aws_iam_role.hook_lambda.arn
  runtime          = "nodejs22.x"
  architectures    = ["arm64"]
  handler          = "index.handler"
  filename         = data.archive_file.hook[each.key].output_path
  source_code_hash = data.archive_file.hook[each.key].output_base64sha256
  timeout          = 60

  depends_on = [aws_cloudwatch_log_group.hook]
}
