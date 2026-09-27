data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Pulls the image and writes logs for the Fargate task.
resource "aws_iam_role" "task_execution" {
  name               = "${var.project_name}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Lets ECS rewrite listener rules and target groups during blue/green.
resource "aws_iam_role" "ecs_load_balancers" {
  name               = "${var.project_name}-ecs-load-balancers"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json
}

resource "aws_iam_role_policy_attachment" "ecs_load_balancers" {
  role       = aws_iam_role.ecs_load_balancers.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"
}

# Lets ECS invoke the lifecycle hook Lambdas.
resource "aws_iam_role" "ecs_hooks" {
  name               = "${var.project_name}-ecs-hooks"
  assume_role_policy = data.aws_iam_policy_document.ecs_trust.json
}

data "aws_iam_policy_document" "ecs_hooks" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [for fn in aws_lambda_function.hook : fn.arn]
  }
}

resource "aws_iam_role_policy" "ecs_hooks" {
  name   = "invoke-hooks"
  role   = aws_iam_role.ecs_hooks.id
  policy = data.aws_iam_policy_document.ecs_hooks.json
}

# Execution role shared by the hook Lambdas.
resource "aws_iam_role" "hook_lambda" {
  name               = "${var.project_name}-hook-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy_attachment" "hook_lambda_logs" {
  role       = aws_iam_role.hook_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "hook_lambda_vpc" {
  role       = aws_iam_role.hook_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Hooks look up the green revision's tasks and image tag.
data "aws_iam_policy_document" "hook_lambda_ecs" {
  statement {
    actions   = ["ecs:ListTasks", "ecs:DescribeTasks"]
    resources = ["*"]
    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [aws_ecs_cluster.this.arn]
    }
  }
  statement {
    actions   = ["ecs:DescribeTaskDefinition"]
    resources = ["*"] # DescribeTaskDefinition does not support resource-level permissions
  }
}

resource "aws_iam_role_policy" "hook_lambda_ecs" {
  name   = "read-green-revision"
  role   = aws_iam_role.hook_lambda.id
  policy = data.aws_iam_policy_document.hook_lambda_ecs.json
}
