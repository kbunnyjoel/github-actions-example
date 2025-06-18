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
