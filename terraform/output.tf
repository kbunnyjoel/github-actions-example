output "kubeconfig_command" {
  description = "Configure kubectl access"
  value       = "aws eks update-kubeconfig --region=${var.aws_region} --name=${var.cluster_name}"
}
output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_id
}

# Output bastion IP
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_dns_name" {
  value = aws_route53_record.bastion_dns.fqdn
}
