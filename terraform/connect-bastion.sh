#!/bin/bash

# Get the current bastion IP from AWS
BASTION_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=bastion-host" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

if [ -z "$BASTION_IP" ]; then
  echo "Error: Could not get bastion IP"
  exit 1
fi

echo "Connecting to bastion host at IP: $BASTION_IP"
ssh -i "$(pwd)/keys/deployment_key.pem" -o StrictHostKeyChecking=no ec2-user@$BASTION_IP