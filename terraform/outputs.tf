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
