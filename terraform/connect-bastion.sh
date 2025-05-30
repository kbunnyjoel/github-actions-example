#!/bin/bash
BASTION_HOST="bastion.bunny970077.com"
BASTION_IP="13.54.11.253"  # Your bastion IP
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

echo "Connecting to bastion host at $BASTION_IP..."
ssh -i "$KEY_PATH" ec2-user@$BASTION_IP
