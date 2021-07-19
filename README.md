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

Probably skip?

```sh
$ kind get clusters
openfaas
$ kind get nodes --name openfaas
openfaas-control-plane
$ kind get kubeconfig --name openfaas > openfaas-kubeconfig
$ export KUBECONFIG="$(pwd)/openfaas-kubeconfig"
$ kubectl cluster-info
Kubernetes master is running at https://127.0.0.1:52800
CoreDNS is running at https://127.0.0.1:52800/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

## Deploy OpenFaaS on Kubernetes with Helm

This installs OpenFaaS, as well as the OpenFaaS CRDs.

```sh
$ cd faas
$ kind get kubeconfig --name openfaas > openfaas-kubeconfig
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

The OpenFaaS gateway allows us to call OpenFaaS functions.

```sh
$ kubectl port-forward svc/gateway -n openfaas 8080:8080 &
```

Running it in the background means you don't have to switch tabs, but log messages get mixed into output, which might be confusing.

## Deploy the nodeinfo openFaaS function

```sh
$ cd ../functions/nodeinfo
$ kind get kubeconfig --name openfaas > openfaas-kubeconfig
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
$ cd ../cows
```

Review `cows.yaml`. Convert it to an HCL manifest.

```
$ echo 'yamldecode(file("cows.yaml"))' | terraform console
```

Add a `kubernetest_manifest` resource for the showcow function. Pasted manifest
will not be formatted correctly.

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
          (__)
    _____| oo |
   /          |
  /           |
 /____________|
    ^^    ^^
Cow dressed up
  as ghost
for Halloween
```

## Cleanup

(Currently in `learn-terraform-k8s-faas-crd/functions/cows`).

- Should we have them destroy the functions & openfaas, since they can just `kind delete` instead?

```sh
$ fg
kubectl port-forward svc/gateway -n openfaas 8080:8080	(wd: ~/code/learn-terraform-k8s-faas-crd/functions/nodeinfo)
<ctrl-c>
$ terraform destroy
$ cd ../nodeinfo
$ terraform destroy
$ cd ../../openfaas
$ terraform destroy
$ cd ..
$ kind delete cluster --name openfaas
```


## Create an OpenFaaS function

NOTE: Probably out of scope - requires:

- Either an account with docker hub, or setting up a private docker registry.
- OpenFaaS CLI

### Private docker registry

Currently commented out in `faas/main.tf`. Doesn't work yet because I 

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

