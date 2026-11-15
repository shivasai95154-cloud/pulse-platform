
# Find the existing default VPC in AWS
data "aws_vpc" "default" {
  default = true
}

# Find the subnets belonging to the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for the Application Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "pulse-platform-alb-sg"
  description = "Allow public HTTP traffic to the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pulse-platform-alb-sg"
  }
}

# Security group for the application EC2 instances
resource "aws_security_group" "app_sg" {
  name        = "pulse-platform-app-sg"
  description = "Allow application traffic only from the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Allow web traffic from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Allow API traffic from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pulse-platform-app-sg"
  }
}
