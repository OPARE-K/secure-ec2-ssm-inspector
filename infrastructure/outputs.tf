output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_http_url" {
  description = "HTTP URL of the Application Load Balancer"
  value       = "http://${aws_lb.alb.dns_name}"
}

output "instance_id" {
  description = "The managed EC2 instance ID"
  value       = aws_instance.web.id
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance (behind ALB)"
  value       = aws_instance.web.private_ip
}
