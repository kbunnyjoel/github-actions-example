#!/bin/bash

NAMESPACE="argocd"
RELEASE_NAME="argocd"

# List of core ArgoCD resources typically needing patching
RESOURCES=(
  "serviceaccount/argocd-server"
  "serviceaccount/argocd-dex-server"
  "serviceaccount/argocd-redis"
  "serviceaccount/argocd-repo-server"
  "serviceaccount/argocd-application-controller"
)

for RESOURCE in "${RESOURCES[@]}"; do
  echo "Patching $RESOURCE in namespace $NAMESPACE..."
  kubectl patch $RESOURCE -n $NAMESPACE --type merge -p "{
    \"metadata\": {
      \"labels\": {
        \"app.kubernetes.io/managed-by\": \"Helm\"
      },
      \"annotations\": {
        \"meta.helm.sh/release-name\": \"$RELEASE_NAME\",
        \"meta.helm.sh/release-namespace\": \"$NAMESPACE\"
      }
    }
  }" || echo "Warning: Failed to patch $RESOURCE. It may not exist yet."
done

echo "✅ Patching complete. You can now run Helm upgrade/install."
