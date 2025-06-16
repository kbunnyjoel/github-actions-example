#!/bin/bash

set -euo pipefail

DOMAIN_NAME="${1:-}"
if [[ -z "$DOMAIN_NAME" ]]; then
  echo "Usage: $0 <domain-name>"
  exit 1
fi

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
