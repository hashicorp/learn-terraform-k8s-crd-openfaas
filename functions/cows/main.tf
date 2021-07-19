terraform {
  required_providers {
    kubernetes-alpha = {
      source  = "hashicorp/kubernetes-alpha"
      version = "0.5.0"
    }
  }
}

provider "kubernetes-alpha" {
  config_path = var.kubeconfig_path
}
