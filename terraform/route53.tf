resource "aws_route53_zone" "main" {
  name = "bunnycloud.xyz"
  # If your zone has specific tags you want to manage with Terraform, add them here.
  # Otherwise, Terraform will ignore existing tags on import unless you define them.
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Add an A record for the apex domain to satisfy Cognito's parent domain validation.
# If bunnycloud.xyz should point to a specific service (e.g., a load balancer or S3 website),
# replace "192.0.2.1" with the appropriate IP or use an ALIAS record.
resource "aws_route53_record" "apex_a_record" {
  zone_id = aws_route53_zone.main.zone_id
  name    = aws_route53_zone.main.name # This will resolve to "bunnycloud.xyz"
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"] # Placeholder IP from TEST-NET-1 (RFC 5737)
}
