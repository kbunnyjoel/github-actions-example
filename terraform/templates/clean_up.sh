#!/bin/bash

set -euo pipefail

VPC_ID="$1"

if [[ -z "$VPC_ID" ]]; then
  echo "❌ Please provide a VPC ID as the first argument."
  exit 1
fi

echo "🔍 Starting cleanup for VPC: $VPC_ID"

# Delete Elastic Network Interfaces (detach if attached before deleting)
for eni in $(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkInterfaces[].NetworkInterfaceId" --output text); do
  echo "🧹 Processing ENI: $eni"
  
  attachment_id=$(aws ec2 describe-network-interfaces --network-interface-ids $eni --query "NetworkInterfaces[0].Attachment.AttachmentId" --output text)

  if [[ "$attachment_id" != "None" ]]; then
    echo "🔌 Detaching ENI: $eni (Attachment ID: $attachment_id)"
    aws ec2 detach-network-interface --attachment-id $attachment_id || true
    sleep 3
  fi

  echo "🧹 Deleting ENI: $eni"
  aws ec2 delete-network-interface --network-interface-id $eni || true
done

# Delete Load Balancers
for lb in $(aws elbv2 describe-load-balancers --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text); do
  echo "🧹 Deleting Load Balancer: $lb"
  aws elbv2 delete-load-balancer --load-balancer-arn $lb || true
done

# Wait for deletion (optional safety delay)
sleep 10

# Delete Target Groups
for tg in $(aws elbv2 describe-target-groups --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text); do
  echo "🧹 Deleting Target Group: $tg"
  aws elbv2 delete-target-group --target-group-arn $tg || true
done

# Delete NAT Gateways
for nat in $(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[].NatGatewayId" --output text); do
  echo "🧹 Deleting NAT Gateway: $nat"
  aws ec2 delete-nat-gateway --nat-gateway-id $nat || true
  sleep 5
  aws ec2 wait nat-gateway-deleted --nat-gateway-ids $nat
done

# Release Elastic IPs
for alloc_id in $(aws ec2 describe-addresses --query "Addresses[].AllocationId" --output text); do
  echo "🧹 Releasing EIP: $alloc_id"
  aws ec2 release-address --allocation-id $alloc_id || true
done

# Detach and delete Internet Gateways
for igw in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[].InternetGatewayId" --output text); do
  echo "🧹 Detaching and deleting IGW: $igw"
  aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $VPC_ID || true
  aws ec2 delete-internet-gateway --internet-gateway-id $igw || true
done

# Delete VPC Endpoints
for vpce in $(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --query "VpcEndpoints[].VpcEndpointId" --output text); do
  echo "🧹 Deleting VPC Endpoint: $vpce"
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $vpce || true
done

# Delete Security Groups (excluding default)
for sg in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text); do
  echo "🧹 Deleting Security Group: $sg"
  aws ec2 delete-security-group --group-id $sg || true
done

# Delete Route Tables (excluding main)
for rt in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[?Associations[?Main!=true]].RouteTableId" --output text); do
  echo "🧹 Deleting Route Table: $rt"
  aws ec2 delete-route-table --route-table-id $rt || true
done

# Delete Subnets
for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text); do
  echo "🧹 Deleting Subnet: $subnet"
  aws ec2 delete-subnet --subnet-id $subnet || true
done

# Final VPC Deletion
echo "🧨 Attempting final VPC delete: $VPC_ID"
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "✅ VPC $VPC_ID cleanup complete."
