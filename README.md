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
- **AWS Cognito** – User authentication provider for secure OIDC/OAuth2 login to your apps
- **Amazon EventBridge** – Scheduled start/stop of EC2/EKS instances for cost optimization
- **Node.js App with EJS** – Example Node.js service using EJS templating with unit tests for core logic

## 🗄️ Terraform Remote State with S3

To ensure consistent infrastructure state across team members, use an AWS S3 bucket as the Terraform backend.

### ✅ Create an S3 Bucket for State

You can manually create a bucket, e.g.:

```bash
aws s3api create-bucket --bucket my-terraform-state-bucket --region us-east-1
```

### ✅ Configure Terraform to Use the S3 Backend

In your `terraform` folder, update `main.tf` or create a `backend.tf` file with:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "state/terraform.tfstate"
    region         = "ap-southeast-2"
  }
}
```

This setup will store your Terraform state in S3, enabling collaboration and persistent infrastructure state tracking.

## 📦 Setup & Deployment

1. **Provision EKS cluster**  
2. **Deploy ArgoCD** via Helm
3. **Install ExternalDNS** with dynamic AWS ALB integration
4. **Deploy your applications** through ArgoCD synced with GitHub Actions
5. **Validate DNS & service availability** automatically in pipeline
6. Configure AWS Cognito for application user authentication and integrate with your application Ingress for OIDC/OAuth2-based access control (optional but recommended)
7. Optionally configure Amazon EventBridge rules to automatically start and stop EKS node group instances on a schedule to optimize costs (e.g., stop dev clusters overnight).
8. **Deploy your Node.js EJS application** with included example `addNumbers()` function and accompanying Jest test cases to validate your business logic.

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
- Integrates with AWS Cognito for secure user authentication
- Automate instance schedules with EventBridge to reduce unnecessary costs while maintaining security

## 📄 License

MIT © 2025 Bunny Kocharla

## 🗺 Architecture Overview

```
[ GitHub Actions ]
        │
        ▼
[ Terraform ]
        │
        ▼
[ AWS EKS (Graviton Nodes) ]
        │
        ├── [ ArgoCD ] ←── GitOps sync from GitHub
        │
        ├── [ ExternalDNS ] ←── Updates Route53 records
        │
        └── [ AWS ALB Ingress Controller ]
                │
                ▼
        [ Deployed Applications ]
                └── [ AWS Cognito ] ←── User authentication (OIDC/OAuth2 integration with Ingress)
                └── [ Amazon EventBridge ] ←── Scheduled start/stop of EKS nodes
                └── [ Node.js EJS App ] ←── Sample service with tested functions
```

- GitHub Actions triggers both Terraform (for infra) and ArgoCD sync (for app deployment).
- ExternalDNS automatically updates Route53 records with ALB-assigned hostnames.
- ALB provides secure HTTPS ingress using ACM certificates.

## 💻 Quick Usage Example

```bash
# 1️⃣ Clone the repo
git clone https://github.com/bunnykocharla/github-actions-example.git
cd github-actions-example

# 2️⃣ Provision EKS infrastructure
cd terraform
terraform init
terraform apply

# 3️⃣ Deploy ArgoCD & ExternalDNS
cd ../k8s
helm install argocd argo/argo-cd -n argocd --create-namespace
helm install externaldns bitnami/external-dns -n externaldns --create-namespace \
  --set provider=aws --set aws.zoneType=public

# 4️⃣ Deploy your app using ArgoCD by pushing manifests to the repo:
git add .
git commit -m "Deploy my awesome app 🚀"
git push

# 5️⃣ Watch GitHub Actions build & ArgoCD sync deploy your app automatically!

# 6️⃣ Run unit tests for your Node.js app
npm install
npm test
```
