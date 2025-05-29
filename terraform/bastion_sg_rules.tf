# Allow the bastion host to communicate with the EKS cluster
resource "aws_security_group_rule" "bastion_to_eks" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.bastion_sg.id
  cidr_blocks       = ["10.0.0.0/16"]  # VPC CIDR block
  description       = "Allow bastion to communicate with EKS API"
}

# Allow the EKS cluster to receive traffic from the bastion host
resource "aws_security_group_rule" "eks_from_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.bastion_sg.id
  description              = "Allow EKS to receive traffic from bastion"
}