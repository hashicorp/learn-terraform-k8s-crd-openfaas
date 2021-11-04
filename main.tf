terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.2.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.7.2"
    }
  }
}

provider "kubernetes" {
  host = var.k8s_host

  client_certificate     = base64decode(var.k8s_client_certificate)
  client_key             = base64decode(var.k8s_client_key)
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
}

resource "kubernetes_namespace" "openfaas" {
  lifecycle {
    ignore_changes = [metadata]
  }

  metadata {
    name = "openfaas"
    labels = {
      role            = "openfaas-system"
      access          = "openfaas-system"
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
      role            = "openfaas-fn"
      istio-injection = "enabled"
    }
  }
}

provider "helm" {
  kubernetes {
    host = var.k8s_host

    client_certificate     = base64decode(var.k8s_client_certificate)
    client_key             = base64decode(var.k8s_client_key)
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  }
}

# Need to wait a few seconds when removing the openfaas resource to give helm
# time to finish cleaning up.
#
# Otherwise, after `terraform destroy`:
# │ Error: uninstallation completed with 1 error(s): uninstall: Failed to purge
#   the release: release: not found

resource "time_sleep" "wait_30_seconds" {
  depends_on = [kubernetes_namespace.openfaas]

  destroy_duration = "30s"
}

resource "helm_release" "openfaas" {
  repository = "https://openfaas.github.io/faas-netes"
  chart      = "openfaas"
  name       = "openfaas"
  namespace  = "openfaas"

  depends_on = [time_sleep.wait_30_seconds]

  set {
    name  = "functionNamepsace"
    value = "openfaas-fn"
  }

  set {
    name  = "generateBasicAuth"
    value = "true"
  }

  set {
    name  = "operator.create"
    value = "true"
  }
}
