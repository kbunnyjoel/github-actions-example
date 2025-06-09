output "kubeconfig_command" {
  description = "Configure kubectl access"
  value       = "aws eks update-kubeconfig --region=${var.aws_region} --name=${var.cluster_name}"
}
output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_id
}

output "bastion_dns_name" {
  description = "The DNS name of the bastion host"
  value       = var.create_dns_records ? aws_route53_record.bastion_dns[0].fqdn : "DNS record not created"
}


# Output bastion Elastic IP
output "bastion_public_ip" {
  description = "The static Elastic IP address of the bastion host."
  value       = aws_eip.bastion_eip.public_ip
}

output "external_dns_role_arn" {
  value = aws_iam_role.external_dns.arn
}

# Output the certificate ARN for use in other resources (e.g., ALB Listener, CloudFront)
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.create_dns_records ? aws_acm_certificate_validation.cert[0].certificate_arn : null
}
