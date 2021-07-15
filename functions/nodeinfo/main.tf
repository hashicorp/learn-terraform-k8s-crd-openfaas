terraform {
  required_providers {
    kubernetes-alpha = {
      source = "hashicorp/kubernetes-alpha"
      version = "0.5.0"
    }
  }
}

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../../k8s-eks/terraform.tfstate"
  }
}

provider "aws" {
  region = data.terraform_remote_state.eks.outputs.aws_region
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "kubernetes-alpha" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)

  exec = {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
    env = { }
  }
}

resource "kubernetes_manifest" "openfaas_fn_nodeinfo" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "openfaas.com/v1"
    "kind" = "Function"
    "metadata" = {
      "name" = "nodeinfo"
      "namespace" = "openfaas-fn"
    }
    "spec" = {
      "environment" = {
        "write_debug" = "true"
      }
      "handler" = "node main.js"
      "image" = "functions/nodeinfo:latest"
      "labels" = {
        "com.openfaas.scale.max" = "15"
        "com.openfaas.scale.min" = "2"
      }
      "limits" = {
        "cpu" = "200m"
        "memory" = "256Mi"
      }
      "name" = "nodeinfo"
      "requests" = {
        "cpu" = "10m"
        "memory" = "128Mi"
      }
    }
  }
}
