output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_alb.main.dns_name
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}
