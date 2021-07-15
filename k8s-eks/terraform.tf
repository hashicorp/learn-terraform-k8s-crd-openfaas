terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.49.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.3.2"
    }
  }

  required_version = "~> 1.0.1"
}

provider "aws" {
  region = var.aws_region
}

# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes

# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}
