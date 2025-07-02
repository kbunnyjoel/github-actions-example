#!/usr/bin/env bash

set -euo pipefail

ARGOCD_HOST="argocd.bunnycloud.xyz"

echo "🔍 Checking HTTP redirect..."
REDIRECT_URL=$(curl -s -o /dev/null -w "%{redirect_url}" "http://$ARGOCD_HOST")

if [[ "$REDIRECT_URL" == https://* ]]; then
  echo "✅ HTTP request correctly redirects to: $REDIRECT_URL"
else
  echo "❌ HTTP did not redirect to HTTPS! Got: '$REDIRECT_URL'"
  exit 1
fi

echo "🔍 Checking HTTPS response..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -k "https://$ARGOCD_HOST")

if [[ "$HTTP_STATUS" == "200" ]]; then
  echo "✅ HTTPS page responded with status 200"
else
  echo "❌ HTTPS page did not respond with status 200, got $HTTP_STATUS"
  exit 1
fi

echo "🔍 Verifying ArgoCD content over HTTPS..."
PAGE_CONTENT=$(curl -sk "https://$ARGOCD_HOST")

if echo "$PAGE_CONTENT" | grep -qi "argo cd"; then
  echo "✅ ArgoCD page loaded successfully over HTTPS"
else
  echo "⚠️ HTTPS page loaded, but could not detect ArgoCD content. Manual check recommended."
fi

echo "🎉 Verification completed!"
