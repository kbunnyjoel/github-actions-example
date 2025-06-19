# Certificate for services requiring us-east-1 (e.g., CloudFront)
resource "aws_acm_certificate" "wildcard_certificate_us_east_1" {
  provider          = aws.us_east_1 # Ensure certificate is created in us-east-1
  domain_name       = "*.bunnycloud.xyz"
  validation_method = "DNS"
  tags = {
    Environment = "dev"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record for the us-east-1 certificate
resource "aws_route53_record" "cert_validation_us_east_1" {
  count = var.create_dns_records ? 1 : 0 # Match conditionality if needed

  zone_id = aws_route53_zone.main.zone_id
  name    = element(aws_acm_certificate.wildcard_certificate_us_east_1.domain_validation_options.*.resource_record_name, 0)
  type    = element(aws_acm_certificate.wildcard_certificate_us_east_1.domain_validation_options.*.resource_record_type, 0)
  records = [element(aws_acm_certificate.wildcard_certificate_us_east_1.domain_validation_options.*.resource_record_value, 0)]
  ttl     = 60
}

# Waits for the us-east-1 ACM certificate to be validated.
resource "aws_acm_certificate_validation" "acm_cert_validation_us_east_1" {
  # Match conditionality if needed, similar to aws_route53_record.cert_validation
  count    = var.create_dns_records ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.wildcard_certificate_us_east_1.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_us_east_1 : record.fqdn] # Use all FQDNs
}

# Certificate for services in ap-southeast-2 (e.g., EKS Load Balancers)
resource "aws_acm_certificate" "wildcard_certificate_ap_southeast_2" {
  # provider is default (ap-southeast-2, as defined in your variables.tf or provider block)
  domain_name       = "*.bunnycloud.xyz"
  validation_method = "DNS"

  tags = {
    Environment = "dev"
    Purpose     = "EKS Load Balancer"
    Region      = var.aws_region # This will be ap-southeast-2
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record for the ap-southeast-2 certificate
resource "aws_route53_record" "cert_validation_ap_southeast_2" {
  count = var.create_dns_records ? 1 : 0
  allow_overwrite = true # Explicitly set, though true is the default

  zone_id = aws_route53_zone.main.zone_id
  name    = element(aws_acm_certificate.wildcard_certificate_ap_southeast_2.domain_validation_options.*.resource_record_name, 0)
  type    = element(aws_acm_certificate.wildcard_certificate_ap_southeast_2.domain_validation_options.*.resource_record_type, 0)
  records = [element(aws_acm_certificate.wildcard_certificate_ap_southeast_2.domain_validation_options.*.resource_record_value, 0)]
  ttl     = 60
}

# Waits for the ap-southeast-2 ACM certificate to be validated.
resource "aws_acm_certificate_validation" "acm_cert_validation_ap_southeast_2" {
  count = var.create_dns_records ? 1 : 0
  # provider is default (ap-southeast-2)

  certificate_arn         = aws_acm_certificate.wildcard_certificate_ap_southeast_2.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_ap_southeast_2 : record.fqdn]
}
