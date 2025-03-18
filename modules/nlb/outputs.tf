output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer."
  value       = aws_lb.nlb.dns_name
}

output "nlb_arn" {
  description = "ARN of the Network Load Balancer."
  value       = aws_lb.nlb.arn
}
