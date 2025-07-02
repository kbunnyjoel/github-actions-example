# ✅ GitHub Actions CI/CD for Kubernetes with ArgoCD 🧮

A practical example project showcasing a **production-ready GitOps pipeline** using **GitHub Actions**, **ArgoCD**, **AWS ALB Ingress**, and **ExternalDNS**.

## 🚀 Features

- ✅ Fully automated CI/CD with GitHub Actions
- ✅ Declarative GitOps deployments with ArgoCD
- ✅ Dynamic DNS management using ExternalDNS + AWS Route53
- ✅ Secure HTTPS ingress with AWS ALB Ingress Controller
- ✅ Dynamic ELB hostname detection with ExternalDNS
- ✅ Integrated Helm chart deployment
- ✅ Automated health checks with robust error handling

## 🛠 Technologies Used

- **GitHub Actions** – CI/CD automation
- **Kubernetes (EKS)** – Container orchestration
- **ArgoCD** – Declarative GitOps CD
- **AWS ALB Ingress Controller** – Ingress management
- **ExternalDNS** – Dynamic DNS in Route53
- **AWS Route53** – DNS hosting
- **Helm** – Kubernetes package manager

## 📦 Setup & Deployment

1. **Provision EKS cluster**  
2. **Deploy ArgoCD** via Helm
3. **Install ExternalDNS** with dynamic AWS ALB integration
4. **Deploy your applications** through ArgoCD synced with GitHub Actions
5. **Validate DNS & service availability** automatically in pipeline

## ✅ CI/CD Status

![CI](https://github.com/bunnykocharla/github-actions-example/actions/workflows/deploy.yml/badge.svg)
![ArgoCD Sync](https://img.shields.io/badge/ArgoCD-Synced-brightgreen?logo=argo)
![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-blue?logo=kubernetes)
![AWS ALB](https://img.shields.io/badge/Ingress-ALB-brightgreen?logo=amazon-aws)
![Helm](https://img.shields.io/badge/Helm-Enabled-blue?logo=helm)
![ExternalDNS](https://img.shields.io/badge/ExternalDNS-Active-success?logo=amazon-aws)

## 🔒 Security & Best Practices

- Uses HTTPS ingress with ACM-managed certificates
- Health checks for application readiness
- GitOps with ArgoCD ensures consistent state
- Automated DNS updates minimize manual configuration

## 📄 License

MIT © 2025 Bunny Kocharla
