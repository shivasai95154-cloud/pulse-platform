
# AWS region
output "aws_region" {
  description = "AWS region used by Pulse Platform"
  value       = var.aws_region
}

# Application Load Balancer DNS
output "alb_dns_name" {
  description = "Public DNS name of Pulse Platform"
  value       = aws_lb.pulse_alb.dns_name
}

# Application Load Balancer URL
output "application_url" {
  description = "Public URL of Pulse Platform"
  value       = "http://${aws_lb.pulse_alb.dns_name}"
}

# EC2 instance IDs
output "ec2_instance_ids" {
  description = "IDs of all four application EC2 instances"
  value = {
    for service, instance in aws_instance.app :
    service => instance.id
  }
}

# EC2 public IP addresses
output "ec2_public_ips" {
  description = "Public IP addresses of application instances"
  value = {
    for service, instance in aws_instance.app :
    service => instance.public_ip
  }
}

# Target group ARNs
output "target_group_arns" {
  description = "ARNs of application target groups"
  value = {
    for service, target_group in aws_lb_target_group.app :
    service => target_group.arn
  }
}
