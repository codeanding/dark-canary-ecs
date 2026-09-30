resource "aws_lb" "this" {
  name               = var.project_name
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    enabled = true
  }

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# Both target groups exist up front; ECS decides which one is "blue" on each deploy.
resource "aws_lb_target_group" "app" {
  for_each = toset(["blue", "green"])

  name                 = "${var.project_name}-${each.key}"
  port                 = var.app_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 5

  health_check {
    path                = "/health"
    interval            = 5
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

locals {
  forward_to_blue = {
    blue  = 100
    green = 0
  }
}

# --- Production -------------------------------------------------------------

resource "aws_lb_listener" "prod" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "no route"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "prod" {
  listener_arn = aws_lb_listener.prod.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  action {
    type = "forward"
    forward {
      dynamic "target_group" {
        for_each = local.forward_to_blue
        content {
          arn    = aws_lb_target_group.app[target_group.key].arn
          weight = target_group.value
        }
      }
    }
  }

  # ECS rewrites the forward weights during every deployment.
  lifecycle {
    ignore_changes = [action]
  }
}

# --- Test (dark canary) -----------------------------------------------------

resource "aws_lb_listener" "test" {
  count = var.test_routing == "port" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "no route"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "test" {
  listener_arn = var.test_routing == "port" ? aws_lb_listener.test[0].arn : aws_lb_listener.prod.arn
  priority     = 10

  dynamic "condition" {
    for_each = var.test_routing == "port" ? [1] : []
    content {
      path_pattern {
        values = ["/*"]
      }
    }
  }

  dynamic "condition" {
    for_each = var.test_routing == "header" ? [1] : []
    content {
      http_header {
        http_header_name = "x-dark-canary"
        values           = ["1"]
      }
    }
  }

  # The header alone is not a secret: also require the source IP to be the presenter or
  # the NAT EIP (hook Lambdas). Everyone else keeps hitting the production rule.
  dynamic "condition" {
    for_each = var.test_routing == "header" ? [1] : []
    content {
      source_ip {
        values = [var.presenter_cidr, "${module.vpc.nat_public_ips[0]}/32"]
      }
    }
  }

  action {
    type = "forward"
    forward {
      dynamic "target_group" {
        for_each = local.forward_to_blue
        content {
          arn    = aws_lb_target_group.app[target_group.key].arn
          weight = target_group.value
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}
