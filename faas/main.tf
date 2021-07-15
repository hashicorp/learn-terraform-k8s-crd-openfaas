terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
}

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../k8s-eks/terraform.tfstate"
#    path = "../../learn-terraform-provision-eks-cluster/terraform.tfstate"
  }
}

# Retrieve EKS cluster information
provider "aws" {
  region = data.terraform_remote_state.eks.outputs.aws_region
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}

resource "kubernetes_namespace" "openfaas" {
  lifecycle {
    ignore_changes = [metadata]
  }

  metadata {
    name = "openfaas"
    labels = {
      role = "openfaas-system"
      access = "openfaas-system"
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_namespace" "openfaas-fn" {
  lifecycle {
    ignore_changes = [metadata]
  }
  metadata {
    name = "openfaas-fn"
    labels = {
      role = "openfaas-fn"
      istio-injection = "enabled"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.aws_eks_cluster.cluster.name
      ]
    }
  }
}

# Need to wait a few seconds when removing the openfaas resource to give helm time to finish cleaning up.
#
# Otherwise, after `terraform destroy`:
# │ Error: uninstallation completed with 1 error(s): uninstall: Failed to purge the release: release: not found

resource "time_sleep" "wait_30_seconds" {
  depends_on = [kubernetes_namespace.openfaas]

  destroy_duration = "30s"
}

resource "helm_release" "openfaas" {
  repository = "https://openfaas.github.io/faas-netes"
  chart = "openfaas"
  name = "openfaas"
  namespace = "openfaas"

  depends_on = [time_sleep.wait_30_seconds]

  set {
    name = "functionNamepsace"
    value = "openfaas-fn"
  }

  set {
    name = "operator.create"
    value = "true"
  }

  set {
    name = "generateBasicAuth"
    value = "true"
  }

  set {
    name = "ingress.enabled"
    value = "true"
  }
}
