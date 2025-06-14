resource "aws_route53_zone" "main" {
  name = "bunnycloud.xyz"
  # If your zone has specific tags you want to manage with Terraform, add them here.
  # Otherwise, Terraform will ignore existing tags on import unless you define them.
  # tags = {
  #   Environment = "production"
  #   ManagedBy   = "Terraform"
  # }
}

output "route53_zone_id" {
  description = "The ID of the Route53 hosted zone."
  value       = aws_route53_zone.main.zone_id
}

output "route53_zone_name_servers" {
  description = "Name servers for the Route53 hosted zone."
  value       = aws_route53_zone.main.name_servers
}
