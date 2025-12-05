# ECR Repository for Gateway
resource "aws_ecr_repository" "gateway" {
  name = "schools-gateway-service"
  force_delete = true
}

# CloudWatch Log Group for Gateway
resource "aws_cloudwatch_log_group" "gateway_log_group" {
  name              = "/ecs/${var.project_name}-gateway-service"
  retention_in_days = 7
}

# Service Discovery for Gateway
resource "aws_service_discovery_service" "gateway" {
  name = "gateway-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Gateway Task Definition
resource "aws_ecs_task_definition" "gateway" {
  family                   = "${var.project_name}-gateway-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "gateway-service"
      image     = "${aws_ecr_repository.gateway.repository_url}:${var.gateway_image_tag}"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8088
          hostPort      = 8088
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.gateway_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# Gateway ECS Service
resource "aws_ecs_service" "gateway" {
  name            = "${var.project_name}-gateway-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.gateway.id
    container_name   = "gateway-service"
    container_port   = 8088
  }

  service_registries {
    registry_arn = aws_service_discovery_service.gateway.arn
  }

  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role_policy]
}
