#!/bin/bash
IP=$(kubectl get svc -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo "{\"argocd_ip\": \"$IP\"}"
