provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}


# Using the main Route53 zone defined in bastion.tf


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0" # Specify a version that supports domain_prefix, e.g., v4.0.0 or newer
    }
    time = { # Assuming you might still want the time_sleep functionality discussed earlier
      source  = "hashicorp/time"
      version = "~> 0.9" # Or your desired version
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.2"
    }
  }

  backend "s3" {
    bucket       = "my-eks-terraform-state-806210429052"
    key          = "eks/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true # NEW in v1.3+
    encrypt      = true
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.github_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.github_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.github_auth.token
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
