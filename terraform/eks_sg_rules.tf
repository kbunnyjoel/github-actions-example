# Additional security group rules for EKS cluster
# These rules allow specific inbound traffic that was previously managed via GitHub Actions

# GitHub Actions HTTPS access is now handled by cluster_endpoint_public_access_cidrs in eks.tf

resource "aws_security_group_rule" "allow_argocd" {
  description       = "Allow ArgoCD UI access"
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["203.0.113.0/24"] # Replace with your actual office IP range
  security_group_id = module.eks.cluster_security_group_id
}