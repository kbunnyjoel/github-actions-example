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

echo "DEBUG: Ingress ELB (from K8s): [$CURRENT_ELB]"
echo "DEBUG: Route53 ELB (from Route53): [$ROUTE53_ELB]"

# Normalize: lowercase and remove trailing dot
K8S_ELB=$(echo "$CURRENT_ELB" | tr '[:upper:]' '[:lower:]' | sed 's/\.$//')
R53_ELB=$(echo "$ROUTE53_ELB" | tr '[:upper:]' '[:lower:]' | sed 's/\.$//')

if [[ -z "$R53_ELB" ]]; then
  echo "❗ Route53 ALIAS record not found for $DOMAIN in hosted zone $HOSTED_ZONE_ID"
  echo "🟢 No existing record to update or delete. Exiting without action."
  exit 0
fi

echo "Normalized Ingress ELB: $K8S_ELB"
echo "Normalized Route53 ELB: $R53_ELB"

if [[ "$K8S_ELB" == "$R53_ELB" ]]; then
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
