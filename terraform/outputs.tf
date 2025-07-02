output "aws_load_balancer_controller_role_arn" {
  description = "The ARN of the IAM role for the AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller_role.arn
}

output "cluster_autoscaler_role_arn" {
  description = "The ARN of the IAM role for the Cluster Autoscaler"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the domain"
  value       = aws_acm_certificate.wildcard_certificate_ap_southeast_2.arn
}
output "ingress_nginx_iam_role_arn" {
  description = "IAM Role ARN for the Ingress NGINX controller"
  value       = aws_iam_role.ingress_nginx.arn
}

output "externaldns_role_arn" {
  description = "The ARN of the IAM role used by ExternalDNS"
  value       = aws_iam_role.external_dns.arn
}

output "argocd_role_arn" {
  description = "The ARN of the IAM role for ArgoCD"
  value       = aws_iam_role.argocd_role.arn
}

output "external_dns_role_arn" {
  description = "The ARN of the IAM role for ArgoCD"
  value       = aws_iam_role.external_dns.arn
}

output "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  value       = aws_route53_zone.main.zone_id
}

output "github_actions_example_certificate_arn" {
  description = "ARN of the ACM certificate for github-actions-example.bunnycloud.xyz"
  value       = aws_acm_certificate.github_actions_example_certificate_ap_southeast_2.arn
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}
