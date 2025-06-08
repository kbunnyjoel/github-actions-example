# IAM role for bastion host
resource "aws_iam_role" "bastion_role" {
  name = "bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create a custom policy for EKS access
resource "aws_iam_policy" "eks_access_policy" {
  name        = "eks-access-policy"
  description = "Policy to allow bastion host to access EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup"
        ]
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*" # STS actions typically require * resource
      }
    ]
  })
}

# Create a custom policy for EC2 read-only access
resource "aws_iam_policy" "ec2_readonly_policy" {
  name        = "ec2-readonly-policy"
  description = "Policy to allow bastion host to read EC2 resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*" # EC2 describe actions require * resource
      }
    ]
  })
}

# Attach the custom EC2 policy to the bastion role
resource "aws_iam_role_policy_attachment" "bastion_ec2_readonly_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.ec2_readonly_policy.arn
}

# Attach the custom policy to the bastion role
resource "aws_iam_role_policy_attachment" "bastion_eks_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.eks_access_policy.arn
}

# Create an instance profile for the bastion host
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-profile"
  role = aws_iam_role.bastion_role.name
}
