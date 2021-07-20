# Manage Kubernetes Custom Resources with Terraform

Demonstrate how to use the kubernetes_alpha provider and Custom Resource
Definitions (CRDs) to managed custom resources.

## Prerequisites

- Terraform CLI
- AWS credentials configured for Terraform
- docker
- KinD CLI
- kubectl CLI

## Clone the repo

```sh
$ git clone https://github.com/hashicorp/learn-terraform-k8s-faas-crd.git
$ cd learn-terraform-k8s-faas-crd
```

## Deploy Kubernetes - KinD

```sh
$ kind create cluster --name openfaas
```

### Verify the cluster

```sh
$ kind get clusters
openfaas
$ kind get kubeconfig --name openfaas > openfaas-kubeconfig
$ export KUBECONFIG="$(pwd)/openfaas-kubeconfig"
$ kubectl cluster-info --context openfaas
```

## Deploy OpenFaaS on Kubernetes with Helm

This installs OpenFaaS, as well as the OpenFaaS CRDs.

```sh
$ cd faas
$ kubectl config view --raw --output go-template-file=../cluster.tfvars.gotemplate > terraform.tfvars
$ terraform init
$ terraform apply
```

### Verify OpenFaaS

```sh
$ kubectl -n openfaas get deployments
```

### List CRDs

```sh
$ kubectl get crds
NAME                                         CREATED AT
functions.openfaas.com                       2021-07-15T19:51:55Z
profiles.openfaas.com                        2021-07-15T19:51:55Z
```

### Describe functions CRD

```sh
$ kubectl describe crds/functions.openfaas.com
```

### Forward OpenFaaS API gateway

The OpenFaaS gateway allows you to call OpenFaaS functions over HTTP.

```sh
$ kubectl port-forward svc/gateway -n openfaas 8080:8080
```

Now, open a new terminal window, change to the top-level
'learn-terraform-k8s-faas-crd' directory, and set up KUBECONFIG again.

```sh
$ export KUBECONFIG="$(pwd)/openfaas-kubeconfig"
```

## Deploy the nodeinfo openFaaS function

NOTE: Probably skipping this, as the next example covers the same things.

```sh
$ cd functions/nodeinfo
$ kubectl config view --raw --output go-template-file=../../cluster.tfvars.gotemplate > terraform.tfvars
$ terraform init
$ terraform apply
```

### Verify OpenFaaS function

Call the function via the Gateway.

```sh
$ curl http://127.0.0.1:8080/function/nodeinfo
Handling connection for 8080
Hostname: nodeinfo-6bd55d47b5-mv49b

Platform: linux
Arch: x64
CPU count: 4
Uptime: 46783
```

## Create manifest for openFaaS function

```sh
$ cd functions/cows
$ kubectl config view --raw --output go-template-file=../../cluster.tfvars.gotemplate > terraform.tfvars
$ terraform init
```

Review `cows.yaml`. Convert it to an HCL manifest.

```
$ echo 'yamldecode(file("cows.yaml"))' | terraform console
```

Add a `kubernetest_manifest` resource for the showcow function. The pasted
manifest will not be formatted correctly.

```hcl
resource "kubernetes_manifest" "openfaas_fn_showcow" {
  provider = kubernetes-alpha

  manifest = {
  "apiVersion" = "openfaas.com/v1"
  "kind" = "Function"
  "metadata" = {
    "name" = "showcow"
    "namespace" = "openfaas-fn"
  }
  "spec" = {
    "handler" = "node show_cow.js"
    "image" = "alexellis2/ascii-cows-openfaas:0.1"
    "name" = "showcow"
  }
}
}
```

Run `terraform fmt` to format your configuration.

```sh
$ terraform fmt
main.tf
```

Apply and test the function.

```sh
$ terraform apply
```

Generate a random ASCII Cow.

```sh
$ curl http://127.0.0.1:8080/function/showcow
  (__) |  (__) |  (__) |  (__) |  (__) |  (__) |
  ( oo |  ( oo |  ( oo |  ( oo |  ( oo |  ( oo |
  /\_| |  /\_| |  /\_| |  /\_| |  /\_| |  /\_| |
-------------------------------------------------
  (__) |  (__) |  (__) |  (__) |  (__) |  (__) |
  ( oo |  ( oo |  ( oo |  ( oo |  ( oo |  ( oo |
  /\_| |  /\_| |  /\_| |  /\_| |  /\_| |  /\_| |
-------------------------------------------------
  (__) |  (__) |  (__) |  (__) |  (__) |  (__) |
  ( oo |  ( oo |  ( oo |  ( oo |  ( oo |  ( oo |
  /\_| |  /\_| |  /\_| |  /\_| |  /\_| |  /\_| |
-------------------------------------------------
  (__) |  (__) |  (__) |  (__) |  (__) |  (__) |
  ( oo |  ( oo |  ( oo |  ( oo |  ( oo |  ( oo |
  /\_| |  /\_| |  /\_| |  /\_| |  /\_| |  /\_| |
-------------------------------------------------
              Andy Warhol Cow
```

### List OpenFaaS function Pods

```sh
$ kubectl get pods --namespace openfaas-fn
NAME                       READY   STATUS    RESTARTS   AGE
showcow-845ff7bdcc-7cq2x   1/1     Running   0          11m
```

### Configure Cows function

Add configuration to the `openfaas_fn_showcow` resource to manage scaling and limits.

```sh
  resource "kubernetes_manifest" "openfaas_fn_showcow" {
    provider = kubernetes-alpha

    manifest = {
      "apiVersion" = "openfaas.com/v1"
      "kind"       = "Function"
      "metadata" = {
        "name"      = "showcow"
        "namespace" = "openfaas-fn"
      }
      "spec" = {
        "handler" = "node show_cow.js"
        "image"   = "alexellis2/ascii-cows-openfaas:0.1"
        "name"    = "showcow"
+        "labels" = {
+          "com.openfaas.scale.max" = "6"
+          "com.openfaas.scale.min" = "4"
+        }
+        "limits" = {
+          "cpu" = "100m"
+          "memory" = "64Mi"
+        }
      }
    }
  }
```

Apply the new configuration.

```sh
$ terraform apply
```

List pods.

```sh
$ kubectl get pods --namespace openfaas-fn
NAME                       READY   STATUS    RESTARTS   AGE
showcow-758b5649f4-6r8nz   1/1     Running   0          7m3s
showcow-758b5649f4-9f8bv   1/1     Running   0          6m53s
showcow-758b5649f4-mv89c   1/1     Running   0          6m57s
showcow-758b5649f4-qgdw9   1/1     Running   0          6m49s
```

It may take a few minutes for the old pod to be Terminated and the new ones to become available.

More cows.

```sh
$ curl http://127.0.0.1:8080/function/showcow
    ___                 __  __
   (( /\   (__)        ( /\/ \(__)
    \\ /\  (oo)         \ /\\/(oo)
 ,----\ /\--\/      ,----\ /\--\/
( ) ) ) // ||      ( ) ) ) // ||
 `-----//--||       `-----//--||
      ^^   ^^            ^^   ^^
              beecows
```

## Cleanup

(Currently in `learn-terraform-k8s-faas-crd/functions/cows`).

Switch to the terminal window running the 'kubectl port-forward' command, and press <ctrl-c> to cancel it.

```sh
$ terraform destroy
$ cd ../../faas
$ terraform destroy
$ cd ..
$ kind delete cluster --name openfaas
```


## Create an OpenFaaS function

NOTE: Probably out of scope for the tutorial.

Requires:

- Either an account with docker hub, or setting up a private docker registry.
- OpenFaaS CLI

### Private docker registry

https://ericstoekl.github.io/faas/operations/managing-images/
or
https://medium.com/twodigits/setup-openfaas-on-k3s-with-local-docker-registry-7a84ebb54a6f

### Install OpenFaaS CLI

```sh
$ curl -sL https://cli.openfaas.com | sudo sh
```

### Generate function template

```sh
$ kubectl get secret -n openfaas basic-auth --output jsonpath="{.data.basic-auth-password}" | base64 --decode | faas-cli login --username admin --password-stdin
$ faas-cli template pull
$ faas-cli new helloworld --lang node12
```

Edit `helloworld/handler.js`:

```javascript
'use strict'

module.exports = async (event, context) => {
  console.log(event);

  const result = {
    'body': "Hello, World!",
    'content-type': event.headers["content-type"]
  }

  return context
    .status(200)
    .succeed(result)
}
```

```sh
#$ faas-cli build -f ./helloworld.yml
#$ faas-cli deploy -f helloworld.yml
$ faas-cli up -f --skip-push
```

```
$ faas-cli generate --namespace openfaas-fn -f helloworld.yml > helloworld_crd.yaml
```

```sh
$ echo 'yamldecode(file("helloworld_crd.yaml"))' | terraform console
```

Paste the output into `main.tf`. Run `terraform fmt`.

```
resource "kubernetes_manifest" "openfaas_fn_helloworld" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "openfaas.com/v1"
    "kind"       = "Function"
    "metadata" = {
      "name" = "helloworld"
    }
    "spec" = {
      "image" = "helloworld:latest"
      "name"  = "helloworld"
    }
  }
}
```

