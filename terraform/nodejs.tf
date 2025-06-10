# Get the Route53 zone
data "aws_route53_zone" "main" {
  name         = "bunnycloud.xyz."
  private_zone = false
}

# Create a DNS record for the application
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "github-actions-example.bunnycloud.xyz"
  type    = "CNAME"
  ttl     = 300
  records = [module.eks.cluster_endpoint]  # This is a placeholder, you'll need to update this
}
