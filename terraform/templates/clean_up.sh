#!/bin/bash

set -euo pipefail

VPC_IDS=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output text)

if [[ -z "$VPC_IDS" ]]; then
  echo "❌ Failed to automatically retrieve VPC IDs."
  exit 1
fi

for VPC_ID in $VPC_IDS; do
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

# Delete Route Tables (disassociate non-main, skip main)
for rt in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[].RouteTableId" --output text); do
  echo "🔍 Checking Route Table: $rt"

  # Disassociate non-main route table associations
  for assoc_id in $(aws ec2 describe-route-tables --route-table-ids $rt --query "RouteTables[0].Associations[?Main==\`false\`].RouteTableAssociationId" --output text); do
    echo "🔌 Disassociating Route Table: $assoc_id"
    aws ec2 disassociate-route-table --association-id $assoc_id || true
  done

  # Check if this is the main route table
  is_main=$(aws ec2 describe-route-tables --route-table-ids $rt --query "RouteTables[0].Associations[?Main==\`true\`]" --output text)

  if [[ -z "$is_main" ]]; then
    echo "🧹 Deleting Route Table: $rt"
    aws ec2 delete-route-table --route-table-id $rt || true
  else
    echo "⚠️ Skipping main route table: $rt"
  fi
done

# Try replacing main route table association to allow deletion
main_assoc_id=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[].Associations[?Main==\`true\`].RouteTableAssociationId" --output text)
alt_rt=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[?Associations[?Main!=\`true\`]].RouteTableId" --output text | awk '{print $1}')

if [[ -n "$main_assoc_id" && -n "$alt_rt" ]]; then
  echo "🔄 Replacing main route table with: $alt_rt"
  aws ec2 replace-route-table-association --association-id $main_assoc_id --route-table-id $alt_rt || true
fi

# Final route table cleanup (now no main should remain)
for rt in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[].RouteTableId" --output text); do
  echo "🧹 Deleting Route Table: $rt"
  aws ec2 delete-route-table --route-table-id $rt || true
done

# Delete Network ACLs (excluding default)
for acl in $(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkAcls[?IsDefault==\`false\`].NetworkAclId" --output text); do
  echo "🧹 Deleting Network ACL: $acl"
  aws ec2 delete-network-acl --network-acl-id $acl || true
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
done

# Delete Route53 records (except NS and SOA) in associated hosted zones
if ! command -v jq &> /dev/null; then
  echo "❌ jq is required for this script. Please install jq and rerun the script."
  exit 1
fi

for zone_id in $(aws route53 list-hosted-zones --query "HostedZones[].Id" --output text | cut -d'/' -f3); do
  echo "🧹 Cleaning Route53 records in hosted zone: $zone_id"
  
  records=$(aws route53 list-resource-record-sets --hosted-zone-id $zone_id \
    --query "ResourceRecordSets[?Type!='NS' && Type!='SOA']" --output json)

  if [[ $records != "[]" ]]; then
    changes=$(echo $records | jq -c '[.[] | {Action: "DELETE", ResourceRecordSet: .}]')
    
    if [[ $changes != "[]" ]]; then
      change_batch="{\"Changes\": $changes}"
      echo "$change_batch" > /tmp/rrset-delete.json
      aws route53 change-resource-record-sets --hosted-zone-id $zone_id --change-batch file:///tmp/rrset-delete.json || true
    fi
  fi
done
