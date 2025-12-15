resource "aws_mq_broker" "rabbitmq" {
  broker_name = "${var.project_name}-rabbitmq"

  engine_type                 = "RabbitMQ"
  engine_version              = var.mq_engine_version
  host_instance_type          = var.mq_instance_type
  deployment_mode             = "SINGLE_INSTANCE"
  publicly_accessible         = false
  auto_minor_version_upgrade  = true
  apply_immediately           = true
  security_groups             = [aws_security_group.mq.id]
  subnet_ids                  = [aws_subnet.private[0].id]

  maintenance_window_start_time {
    day_of_week = "SUNDAY"
    time_of_day = "03:00"
    time_zone   = "UTC"
  }

  logs {
    general = true
  }

  user {
    username       = var.mq_username
    password       = var.mq_password
    console_access = true
  }

  tags = {
    Name = "${var.project_name}-rabbitmq"
  }
}
