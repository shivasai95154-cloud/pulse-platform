
# Find the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Define the four application servers
locals {
  services = {
    web = {
      name           = "Pulse-Web"
      container_port = 80
    }

    arcade = {
      name           = "Pulse-Arcade"
      container_port = 80
    }

    tasks = {
      name           = "Pulse-Tasks"
      container_port = 80
    }

    api = {
      name           = "Pulse-API"
      container_port = 8000
    }
  }
}

# Create one EC2 instance for each application
resource "aws_instance" "app" {
  for_each = local.services

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  # Distribute EC2 instances across available subnets
  subnet_id = element(
    sort(data.aws_subnets.default.ids),
    index(keys(local.services), each.key) % length(data.aws_subnets.default.ids)
  )

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    dnf update -y
    dnf install -y docker git

    systemctl enable docker
    systemctl start docker

    mkdir -p /opt/pulse-platform

    git clone --depth 1 \
      https://github.com/shivasai95154-cloud/pulse-platform.git \
      /opt/pulse-platform

    cd /opt/pulse-platform/services/${each.key}

    docker build -t pulse-${each.key}:latest .

    docker run -d \
      --name pulse-${each.key} \
      --restart unless-stopped \
      -p ${each.value.container_port}:${each.value.container_port} \
      pulse-${each.key}:latest
  EOF

  tags = {
    Name        = each.value.name
    Project     = "PulsePlatform"
    Environment = "Development"
    Service     = each.key
  }
}
