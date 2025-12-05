# Application Load Balancer
resource "aws_alb" "main" {
  name            = "${var.project_name}-alb"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.alb.id]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group
resource "aws_alb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# Listener
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
}
