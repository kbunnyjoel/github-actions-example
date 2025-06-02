# ---------------------------------------------------------------------------------------------------------------------
# BASTION HOST SCHEDULING
# ---------------------------------------------------------------------------------------------------------------------

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

  tags = {
    Name        = "eventbridge-ssm-role"
    Environment = "dev"
    Project     = "github-actions-example"
  }
}

resource "aws_iam_role_policy_attachment" "eventbridge_ssm_policy" {
  role       = aws_iam_role.eventbridge_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
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

resource "aws_cloudwatch_event_target" "stop_bastion_weekdays" {
  rule      = aws_cloudwatch_event_rule.stop_bastion_weekdays.name
  target_id = "stop-bastion"
  arn       = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:automation-definition/AWS-StopEC2Instance"
  role_arn  = aws_iam_role.eventbridge_ssm_role.arn

  input = jsonencode({
    InstanceId = [aws_instance.bastion.id]
  })
}

resource "aws_cloudwatch_event_target" "start_bastion_weekdays" {
  rule      = aws_cloudwatch_event_rule.start_bastion_weekdays.name
  target_id = "start-bastion"
  arn       = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:automation-definition/AWS-StartEC2Instance"
  role_arn  = aws_iam_role.eventbridge_ssm_role.arn

  input = jsonencode({
    InstanceId = [aws_instance.bastion.id]
  })
}
