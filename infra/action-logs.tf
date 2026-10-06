# ECS Action Logs: every step ECS takes during a deployment, delivered to CloudWatch Logs.

resource "aws_cloudwatch_log_group" "action_logs" {
  name              = "/aws/vendedlogs/ecs/action-logs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_resource_policy" "action_logs" {
  resource_arn = aws_cloudwatch_log_group.action_logs.arn
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "delivery.logs.amazonaws.com" }
      Action    = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource  = "${aws_cloudwatch_log_group.action_logs.arn}:log-stream:*"
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.this.account_id }
        ArnLike      = { "aws:SourceArn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.this.account_id}:*" }
      }
    }]
  })
}

resource "aws_cloudwatch_log_delivery_source" "action_logs" {
  name         = "${var.project_name}-action-logs"
  resource_arn = aws_ecs_cluster.this.arn
  log_type     = "ACTION_LOGS"
}

resource "aws_cloudwatch_log_delivery_destination" "action_logs" {
  name          = "${var.project_name}-action-logs"
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.action_logs.arn
  }
}

resource "aws_cloudwatch_log_delivery" "action_logs" {
  delivery_source_name     = aws_cloudwatch_log_delivery_source.action_logs.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.action_logs.arn

  depends_on = [aws_cloudwatch_log_resource_policy.action_logs]
}
