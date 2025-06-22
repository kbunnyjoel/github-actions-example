#!/bin/bash

set -euo pipefail


echo "🔍 Discovering Hosted Zones..."
DOMAIN_NAME=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Config.PrivateZone==\`false\`].[Name]" \
  --output text | head -n 1 | sed 's/\.$//')

if [[ -z "$DOMAIN_NAME" ]]; then
  echo "❌ No public hosted zones found in Route 53."
  exit 1
fi

echo "🔍 Using domain: $DOMAIN_NAME"

echo "🔍 Looking up Hosted Zone ID for domain: $DOMAIN_NAME"
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name "$DOMAIN_NAME" \
  --query "HostedZones[?Name == '${DOMAIN_NAME}.'].Id" \
  --output text | cut -d'/' -f3)

if [[ -z "$HOSTED_ZONE_ID" ]]; then
  echo "❌ Hosted zone not found for domain: $DOMAIN_NAME"
  exit 1
fi

echo "✅ Found Hosted Zone ID: $HOSTED_ZONE_ID"

echo "📥 Fetching non-default Route53 records..."
aws route53 list-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --query "ResourceRecordSets[?Type != 'NS' && Type != 'SOA']" \
  --output json > records-to-delete.json

RECORD_COUNT=$(jq length records-to-delete.json)
if [[ "$RECORD_COUNT" -eq 0 ]]; then
  echo "ℹ️ No non-default records found. Nothing to delete."
else
  echo "🛠️ Preparing delete batch for $RECORD_COUNT records..."
  jq -n --argjson records "$(cat records-to-delete.json)" '{
    Changes: ($records | map({
      Action: "DELETE",
      ResourceRecordSet: .
    }))
  }' > delete-batch.json

  echo "🗑️ Deleting records from Route53..."
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch file://delete-batch.json
  echo "✅ Deletion request submitted."
fi

echo "🔍 Deleting Load Balancers..."
for lb in $(aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerArn' --output text); do
  echo "🗑️ Deleting Load Balancer: $lb"
  aws elbv2 delete-load-balancer --load-balancer-arn "$lb"
done

echo "🔍 Deleting NAT Gateways..."
for nat in $(aws ec2 describe-nat-gateways --query 'NatGateways[*].NatGatewayId' --output text); do
  echo "🗑️ Deleting NAT Gateway: $nat"
  aws ec2 delete-nat-gateway --nat-gateway-id "$nat"
done

echo "🔍 Releasing Elastic IPs..."
for alloc_id in $(aws ec2 describe-addresses --query 'Addresses[*].AllocationId' --output text); do
  echo "🗑️ Releasing Elastic IP: $alloc_id"
  aws ec2 release-address --allocation-id "$alloc_id"
done

echo "🔍 Deleting Network Interfaces..."
for eni in $(aws ec2 describe-network-interfaces --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text); do
  echo "🗑️ Deleting Network Interface: $eni"
  aws ec2 delete-network-interface --network-interface-id "$eni"
done
