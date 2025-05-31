# Create IAM role for EventBridge to invoke SSM
resource "aws_iam_role" "eventbridge_ssm_role" {
  name = "eventbridge-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

# Attach SSM policy to the role
resource "aws_iam_role_policy_attachment" "eventbridge_ssm_policy" {
  role       = aws_iam_role.eventbridge_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# Update the EventBridge target to include the role
resource "aws_cloudwatch_event_target" "stop_bastion_weekdays" {
  rule      = aws_cloudwatch_event_rule.stop_bastion_weekdays.name
  target_id = "stop-bastion"
  arn       = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:automation-definition/AWS-StopEC2Instance"
  role_arn  = aws_iam_role.eventbridge_ssm_role.arn

  input = jsonencode({
    InstanceId = [aws_instance.bastion.id]
  })
}

# Also update the start target
resource "aws_cloudwatch_event_target" "start_bastion_weekdays" {
  rule      = aws_cloudwatch_event_rule.start_bastion_weekdays.name
  target_id = "start-bastion"
  arn       = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:automation-definition/AWS-StartEC2Instance"
  role_arn  = aws_iam_role.eventbridge_ssm_role.arn

  input = jsonencode({
    InstanceId = [aws_instance.bastion.id]
  })
}

resource "aws_cloudwatch_event_rule" "stop_bastion_weekdays" {
  name                = "stop-bastion-weekdays"
  description         = "Stop bastion host outside working hours on weekdays"
  schedule_expression = "cron(0 18 ? * MON-FRI *)" # 6 PM UTC
}

resource "aws_cloudwatch_event_rule" "start_bastion_weekdays" {
  name                = "start-bastion-weekdays"
  description         = "Start bastion host during working hours on weekdays"
  schedule_expression = "cron(0 8 ? * MON-FRI *)" # 8 AM UTC
}

# Create IAM role for VPC CNI
resource "aws_iam_role" "vpc_cni" {
  name = "eks-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-node"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach the required policy to the VPC CNI role
resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Create IAM policy for cluster autoscaler
resource "aws_iam_policy" "cluster_autoscaler_role_policy" {
  name        = "eks-cluster-autoscaler-policy"
  description = "EKS cluster autoscaler policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "cluster_autoscaler_role_policy" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler_role_policy.arn
}

# Create IAM role for cluster autoscaler
resource "aws_iam_role" "cluster_autoscaler" {
  name = "eks-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}
