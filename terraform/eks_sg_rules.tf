# Additional security group rules for EKS cluster
# These rules allow specific inbound traffic that was previously managed via GitHub Actions

resource "aws_security_group_rule" "allow_https" {
  description       = "Allow HTTPS inbound from GitHub Actions"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["140.82.112.0/20"] # GitHub Actions IP range
  security_group_id = module.eks.cluster_security_group_id
}

resource "aws_security_group_rule" "allow_argocd" {
  description       = "Allow ArgoCD UI access"
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["203.0.113.0/24"] # Replace with your actual office IP range
  security_group_id = module.eks.cluster_security_group_id
}
