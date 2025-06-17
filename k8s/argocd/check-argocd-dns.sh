#!/bin/bash

set -e

NAMESPACE="argocd"
INGRESS_NAME="argocd-server"
DOMAIN="argocd.bunnycloud.xyz"
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${DOMAIN#*.}" --query "HostedZones[0].Id" --output text | sed 's|/hostedzone/||')

echo "Fetching current ELB address from Ingress..."
CURRENT_ELB=$(kubectl -n $NAMESPACE get ingress $INGRESS_NAME -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Fetching Route53 A/ALIAS record..."
ROUTE53_RECORD=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query "ResourceRecordSets[?Name == '${DOMAIN}.']" --output json)
ROUTE53_ELB=$(echo "$ROUTE53_RECORD" | jq -r '.[0].AliasTarget.DNSName // empty')

echo "Ingress ELB: $CURRENT_ELB"
echo "Route53 ALIAS: $ROUTE53_ELB"

if [[ "$CURRENT_ELB" == "${ROUTE53_ELB%.}" ]]; then
  echo "✅ Route53 record matches the current Ingress ELB."
else
  echo "❌ Mismatch detected! Route53 ALIAS does not match Ingress ELB."
  echo "You can delete the old Route53 record to let ExternalDNS recreate it."
  read -p "Delete the old record from Route53 now? (y/N): " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    CHANGE_BATCH=$(cat <<EOF
{
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "${DOMAIN}.",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "$(echo "$ROUTE53_RECORD" | jq -r '.[0].AliasTarget.HostedZoneId')",
          "DNSName": "$ROUTE53_ELB",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
EOF
)
    echo "$CHANGE_BATCH" > /tmp/r53-change-batch.json
    aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file:///tmp/r53-change-batch.json
    echo "🗑️ Deleted old record. ExternalDNS will recreate the correct one on the next sync."
  else
    echo "⚠️  Skipped deleting Route53 record."
  fi
fi
