# ✅ GitHub Actions Example 🧮

A sample project demonstrating how to use **GitHub Actions** for CI/CD in a Kubernetes environment using **ArgoCD**, **ExternalDNS**, and **NGINX Ingress Controller**.

## ✅ Features

- Automated CI/CD pipeline via GitHub Actions
- ArgoCD integration for declarative GitOps deployments
- ExternalDNS for dynamic DNS record management in AWS Route 53
- NGINX Ingress Controller for exposing services
- Helm chart templating with dynamic ELB hostname configuration
- Robust error handling and self-healing deployment pipeline

## ✅ Technologies Used

- GitHub Actions
- Kubernetes (EKS)
- ArgoCD
- ExternalDNS
- AWS Route 53
- Helm
- NGINX Ingress

## ✅ Setup & Deployment

1. **Provision EKS Cluster** (once)
2. **Deploy ArgoCD**
3. **Install ExternalDNS** with dynamic ELB targeting
4. **Deploy Applications** via GitHub Actions pipeline
5. **Validate DNS** and service availability

## ✅ Status

![CI](https://github.com/bunnykocharla/github-actions-example/actions/workflows/deploy.yml/badge.svg)
![ArgoCD Sync](https://img.shields.io/badge/ArgoCD-Synced-brightgreen?logo=argo)

## ✅ License

MIT © 2025 Bunny Kocharla
