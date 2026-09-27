output "prod_url" {
  value = "http://${aws_lb.this.dns_name}"
}

output "test_url" {
  value = var.test_routing == "port" ? "http://${aws_lb.this.dns_name}:8080" : "http://${aws_lb.this.dns_name} (header x-dark-canary: 1)"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}
