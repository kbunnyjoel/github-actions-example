#!/bin/bash
KEY_PATH="/Users/bunnykocharla/Repositories/Github actions/github-actions-example/terraform/keys/deployment_key.pem"
TERRAFORM_DIR="/Users/bunnykocharla/Repositories/Github actions/github-actions-example/terraform"

# Check if the key file exists
if [ ! -f "$KEY_PATH" ]; then
  echo "Error: Key file not found at $KEY_PATH"
  exit 1
fi

# Fix key file permissions
chmod 400 "$KEY_PATH"

# Get bastion IP from Terraform output
echo "Fetching bastion IP from Terraform output..."
cd "$TERRAFORM_DIR"
BASTION_IP=$(terraform output -raw bastion_public_ip)

if [ -z "$BASTION_IP" ] || [ "$BASTION_IP" == "None" ]; then
  echo "Error: Could not fetch bastion IP from Terraform output"
  exit 1
fi

echo "Bastion IP: $BASTION_IP"

# Get your current public IP
MY_IP=$(curl -s https://checkip.amazonaws.com)
echo "Your current public IP: $MY_IP"

echo "To allow your IP in the security group, run:"
echo "terraform apply -var=\"allowed_ssh_cidr_blocks=[\\\"$MY_IP/32\\\"]\" -auto-approve"

# Check if the bastion host is reachable
echo "Checking if bastion host is reachable..."
ping -c 3 $BASTION_IP
if [ $? -ne 0 ]; then
  echo "Warning: Bastion host is not responding to ping. This might be expected if ICMP is blocked."
fi

# Check if port 22 is open
echo "Checking if SSH port is open..."
nc -zv $BASTION_IP 22 -w 5
if [ $? -ne 0 ]; then
  echo "Error: SSH port 22 is not open on the bastion host."
  echo "Please run the terraform apply command above to allow your IP."
  exit 1
fi

echo "Connecting to bastion host at $BASTION_IP..."
ssh -i "$KEY_PATH" ec2-user@$BASTION_IP -v
