resource "aws_acm_certificate" "wildcard_certificate" {
  domain_name       = "*.bunnycloud.xyz"
  validation_method = "DNS"

  tags = {
    Environment = "dev"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation record for the certificate
# This creates the CNAME record required by ACM in your Route 53 zone.
# It assumes you want to validate for the first domain_validation_options entry.
# If you have Subject Alternative Names (SANs), you'd iterate or create records for each.
resource "aws_route53_record" "cert_validation" {
  # Ensure the Route 53 zone is available (using your existing data source)
  # The count = var.create_dns_records ? 1 : 0 on your data source needs to be considered.
  # If data.aws_route53_zone.main is conditional, this resource should also be conditional.
  # For simplicity, assuming data.aws_route53_zone.main[0] is always available when this is desired.
  count = var.create_dns_records ? 1 : 0 # Match conditionality if needed

  zone_id = data.aws_route53_zone.bunnycloud.zone_id
  name    = element(aws_acm_certificate.wildcard_certificate.domain_validation_options.*.resource_record_name, 0)
  type    = element(aws_acm_certificate.wildcard_certificate.domain_validation_options.*.resource_record_type, 0)
  records = [element(aws_acm_certificate.wildcard_certificate.domain_validation_options.*.resource_record_value, 0)]
  ttl     = 60
}

# Waits for the ACM certificate to be validated using the DNS record.
resource "aws_acm_certificate_validation" "acm_cert_validation" {
  # Match conditionality if needed, similar to aws_route53_record.cert_validation
  count = var.create_dns_records ? 1 : 0

  certificate_arn         = aws_acm_certificate.wildcard_certificate.arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn] # Use the FQDN of the created record
}

data "aws_route53_zone" "bunnycloud" {
  name = "bunnycloud.xyz"
}
