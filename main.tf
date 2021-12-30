terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.7.1"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.7.2"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

locals {
  config_path = "~/.kube/config"
}

provider "kubernetes" {
  config_path = local.config_path
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
    config_path = local.config_path
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
  chart     = "${path.module}/faas-netes/chart/openfaas"
  name      = "openfaas"
  namespace = "openfaas"

  depends_on = [time_sleep.wait_30_seconds]

  ## helm show values openfaas/openfaas
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

  set {
    name  = "openfaasPRO"
    value = "false"
  }

  timeout         = 100
  force_update    = true
  recreate_pods   = true
  cleanup_on_fail = true
  #disable_webhooks = true
  #wait             = false
}
