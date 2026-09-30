locals {
  test_url = var.test_routing == "port" ? "http://${aws_lb.this.dns_name}:8080" : "http://${aws_lb.this.dns_name}"

  hooks = {
    post-scale-up-smoke = {
      stages  = ["POST_SCALE_UP"]
      details = null
    }
    test-traffic-validation = {
      stages = ["TEST_TRAFFIC_SHIFT"]
      details = jsonencode({
        testUrl          = local.test_url
        testHeader       = var.test_routing == "header" ? "x-dark-canary:1" : null
        rounds           = 4
        requestsPerRound = 10
      })
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

  # In the VPC: the smoke hook calls green task IPs directly; the validation hook
  # reaches the test rule through the NAT EIP (allowed by the rule's source-IP condition).
  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.hook_lambda.id]
  }

  depends_on = [
    aws_cloudwatch_log_group.hook,
    aws_iam_role_policy_attachment.hook_lambda_vpc,
  ]
}
