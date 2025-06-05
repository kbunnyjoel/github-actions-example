output "kubeconfig_command" {
  description = "Configure kubectl access"
  value       = "aws eks update-kubeconfig --region=${var.aws_region} --name=${var.cluster_name}"
}
output "eks_cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_id
}

output "bastion_dns_name" {
  value = aws_route53_record.bastion_dns.fqdn
}

# Output bastion Elastic IP
output "bastion_public_ip" {
  description = "The static Elastic IP address of the bastion host."
  value       = aws_eip.bastion_eip.public_ip
}


output "ingress_hostname" {
  value       = data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname
  description = "The hostname of the ingress ELB"
}

output "ingress_zone_id" {
  value       = data.aws_elb_service_account.main.zone_id
  description = "The hosted zone ID for the ingress ELB"
}
