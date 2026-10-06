resource "aws_ecs_cluster" "this" {
  name = var.project_name
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.project_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64" # images are built on Apple silicon
  }

  container_definitions = jsonencode([{
    name         = "app"
    image        = "${aws_ecr_repository.app.repository_url}:${var.app_image_tag}"
    essential    = true
    portMappings = [{ containerPort = var.app_port, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "app"
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name            = var.project_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  propagate_tags  = "SERVICE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app["blue"].arn
    container_name   = "app"
    container_port   = var.app_port

    advanced_configuration {
      alternate_target_group_arn = aws_lb_target_group.app["green"].arn
      production_listener_rule   = aws_lb_listener_rule.prod.arn
      test_listener_rule         = aws_lb_listener_rule.test.arn
      role_arn                   = aws_iam_role.ecs_load_balancers.arn
    }
  }

  # Without it, a revision that never starts retries forever. Threshold: scripts/ecs.mjs.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_configuration {
    strategy             = "BLUE_GREEN"
    bake_time_in_minutes = 1

    dynamic "lifecycle_hook" {
      for_each = local.hooks
      content {
        hook_target_arn  = aws_lambda_function.hook[lifecycle_hook.key].arn
        role_arn         = aws_iam_role.ecs_hooks.arn
        lifecycle_stages = lifecycle_hook.value.stages
        hook_details     = lifecycle_hook.value.details
      }
    }

    # Holds the deployment with green validated and prod still on blue.
    dynamic "lifecycle_hook" {
      for_each = var.pause_before_production ? [1] : []
      content {
        target_type      = "PAUSE"
        lifecycle_stages = ["POST_TEST_TRAFFIC_SHIFT"]
        timeout_configuration {
          timeout_in_minutes = 60
          action             = "ROLLBACK"
        }
      }
    }
  }

  # Deploys go through scripts/deploy.sh (aws ecs update-service), not terraform apply.
  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_load_balancers,
    aws_iam_role_policy.ecs_hooks,
  ]
}
