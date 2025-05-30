#!/bin/bash
BASTION_HOST="bastion.bunny970077.com"
KEY_PATH="/Users/bunnykocharla/Repositories/Github actions/github-actions-example/terraform/keys/deployment_key.pem"

# Check if the key file exists
if [ ! -f "$KEY_PATH" ]; then
  echo "Error: Key file not found at $KEY_PATH"
  exit 1
fi

# Check key file permissions
KEY_PERMS=$(stat -f "%Lp" "$KEY_PATH")
if [ "$KEY_PERMS" != "400" ]; then
  echo "Warning: Key file permissions should be 400, fixing..."
  chmod 400 "$KEY_PATH"
fi

# Get bastion IP from AWS
echo "Fetching bastion IP from AWS..."
BASTION_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=bastion-host" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

if [ -z "$BASTION_IP" ] || [ "$BASTION_IP" == "None" ]; then
  echo "Error: Could not fetch bastion IP from AWS"
  echo "Using hardcoded IP as fallback"
  BASTION_IP=$BASTION_IP  # Fallback to hardcoded IP
else
  echo "Found bastion IP: $BASTION_IP"
fi

echo "Connecting to bastion host at $BASTION_IP..."
ssh -i "$KEY_PATH" ec2-user@$BASTION_IP
