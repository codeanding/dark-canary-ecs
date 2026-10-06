output "prod_url" {
  description = "Production URL: what every user hits (blue until a deployment shifts production traffic)."
  value       = "http://${aws_lb.this.dns_name}"
}

output "test_url" {
  description = "Test traffic URL. In header mode, send the test header from an allowed IP to reach green."
  value       = var.test_routing == "port" ? local.test_url : "${local.test_url} (header ${local.test_header_name}: ${local.test_header_value})"
}

output "ecr_repository_url" {
  description = "ECR repository the scripts push app images to."
  value       = aws_ecr_repository.app.repository_url
}

output "cluster_name" {
  description = "ECS cluster name (also the task definition family prefix)."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service that runs the blue/green deployments."
  value       = aws_ecs_service.app.name
}
