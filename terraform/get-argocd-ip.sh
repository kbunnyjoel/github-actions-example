#!/bin/bash
IP=$(kubectl get svc argocd-server -n argocd -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo "{\"argocd_ip\": \"$IP\"}"
