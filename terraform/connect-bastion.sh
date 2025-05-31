#!/bin/bash
BASTION_HOST="bastion.bunnycloud.xyz"
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

CONNECT_TARGET="$BASTION_HOST" # Default to BASTION_HOST

if [ -n "$BASTION_IP" ] && [ "$BASTION_IP" != "None" ]; then
  echo "Successfully fetched dynamic bastion IP: $BASTION_IP"
  CONNECT_TARGET="$BASTION_IP"
else
  echo "Error: Could not fetch bastion IP from AWS"
  echo "Falling back to pre-configured BASTION_HOST: $BASTION_HOST"
  # CONNECT_TARGET is already set to BASTION_HOST
fi

if [ -z "$CONNECT_TARGET" ]; then
  echo "Error: Bastion connection target could not be determined. Ensure BASTION_HOST is set."
  exit 1
fi

echo "Connecting to bastion host at $CONNECT_TARGET to update kubeconfig..."
ssh -i "$KEY_PATH" ec2-user@"$CONNECT_TARGET" "aws eks update-kubeconfig --region ap-southeast-2 --name github-actions-eks-example && echo 'Success: Kubeconfig updated on bastion host ($CONNECT_TARGET). You can now SSH into the bastion and use kubectl.'"
