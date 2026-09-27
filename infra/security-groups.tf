resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "ALB: production open, test listener restricted"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_prod" {
  security_group_id = aws_security_group.alb.id
  description       = "Production listener"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# Test listener: only the presenter and the NAT EIP (hook Lambdas egress through it).
resource "aws_vpc_security_group_ingress_rule" "alb_test" {
  # Static keys: the NAT EIP is only known after apply.
  for_each = var.test_routing == "port" ? {
    presenter = var.presenter_cidr
    nat       = "${module.vpc.nat_public_ips[0]}/32"
  } : {}

  security_group_id = aws_security_group.alb.id
  description       = "Test listener"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.tasks.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_security_group" "tasks" {
  name        = "${var.project_name}-tasks"
  description = "Fargate tasks"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "tasks_from_alb" {
  security_group_id            = aws_security_group.tasks.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "tasks_all" {
  security_group_id = aws_security_group.tasks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
