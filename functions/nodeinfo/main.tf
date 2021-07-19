terraform {
  required_providers {
    kubernetes-alpha = {
      source = "hashicorp/kubernetes-alpha"
      version = "0.5.0"
    }
  }
}

provider "kubernetes-alpha" {
  config_path = var.kubeconfig_path
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
