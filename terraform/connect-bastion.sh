#!/bin/bash
KEY_PATH="/Users/bunnykocharla/Repositories/Github actions/github-actions-example/terraform/keys/deployment_key.pem"

# Check if the key file exists
if [ ! -f "$KEY_PATH" ]; then
  echo "Error: Key file not found at $KEY_PATH"
  exit 1
fi

# Fix key file permissions
chmod 400 "$KEY_PATH"

# Get bastion IP from AWS
echo "Fetching bastion IP from AWS..."
BASTION_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=bastion" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

if [ -z "$BASTION_IP" ] || [ "$BASTION_IP" == "None" ]; then
  echo "Error: Could not fetch bastion IP from AWS"
  exit 1
fi

echo "Connecting to bastion host at $BASTION_IP..."
ssh -i "$KEY_PATH" ec2-user@$BASTION_IP
