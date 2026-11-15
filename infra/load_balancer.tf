
# Create an Application Load Balancer
resource "aws_lb" "pulse_alb" {
  name               = "pulse-platform-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name    = "pulse-platform-alb"
    Project = "PulsePlatform"
  }
}

# Create a target group for each application
resource "aws_lb_target_group" "app" {
  for_each = local.services

  name        = "pulse-${each.key}-tg"
  port        = each.value.container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = each.key == "api" ? "/api/health" : "/"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name    = "pulse-${each.key}-tg"
    Project = "PulsePlatform"
  }
}

# Register each EC2 instance with its corresponding target group
resource "aws_lb_target_group_attachment" "app" {
  for_each = aws_instance.app

  target_group_arn = aws_lb_target_group.app[each.key].arn
  target_id        = each.value.id
  port             = local.services[each.key].container_port
}

# Create the public HTTP listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.pulse_alb.arn
  port              = 80
  protocol          = "HTTP"

  # The homepage is the default destination
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["web"].arn
  }
}

# Route Arcade requests
resource "aws_lb_listener_rule" "arcade" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["arcade"].arn
  }

  condition {
    path_pattern {
      values = ["/arcade", "/arcade/*"]
    }
  }
}

# Route Tasks requests
resource "aws_lb_listener_rule" "tasks" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["tasks"].arn
  }

  condition {
    path_pattern {
      values = ["/tasks", "/tasks/*"]
    }
  }
}

# Route API requests
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["api"].arn
  }

  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
}
