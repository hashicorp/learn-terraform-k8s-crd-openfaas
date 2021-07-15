# Manage Kubernetes Custom Resources with Terraform

## Prerequisites

- Terraform CLI
- AWS credentials configured for Terraform
- kubectl CLI
- OpenFaaS CLI (see below)

## Install OpenFaaS CLI

Seems totally safe...

```sh
$ curl -sL https://cli.openfaas.com | sudo sh
```

FIXME: brew/Chocolatey

## Clone the repo

```sh
$ git clone https://
$ cd learn-terraform-k8s-faas-crd
```

## Deploy Kubernetes

We could also use kind or similar instead?

```sh
$ cd k8s-eks
$ terraform init
$ terraform apply
```

This apply takes about 10 minutes to complete.

### Verify the cluster

FIXME: There are easier ways to do auth/kubeconfig, probably?

```sh
$ terraform output -raw kubectl_config > kubectl_config
$ export KUBECONFIG=./kubectl_config
$ kubectl cluster-info
```

## Deploy OpenFaaS on Kubernetes with Helm

This installs OpenFaaS, as well as the OpenFaaS CRDs.

```sh
$ cd ../faas
$ terraform init
$ terraform apply
```

### Verify OpenFaaS

```sh
$ terraform output -raw kubectl_config > kubectl_config
$ export KUBECONFIG=./kubectl_config
$ kubectl -n openfaas get deployments
```

### List CRDs

```sh
$ kubectl get crds
NAME                                         CREATED AT
eniconfigs.crd.k8s.amazonaws.com             2021-07-15T19:25:39Z
functions.openfaas.com                       2021-07-15T19:51:55Z
profiles.openfaas.com                        2021-07-15T19:51:55Z
securitygrouppolicies.vpcresources.k8s.aws   2021-07-15T19:25:43Z
```

### Forward OpenFaaS API gateway

```sh
$ kubectl port-forward svc/gateway -n openfaas 8080:8080 &
```

Running it in the background means you don't have to switch tabs, but log messages get mixed into output, which might be confusing.

## Deploy an openFaaS function

FIXME: Any other functions to use instead/in addition to?

```sh
$ cd ../functions/nodeinfo
$ terraform init
$ terraform apply
```

### Verify OpenFaaS function

```sh
$ kubectl get secret -n openfaas basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode | faas-cli login --username admin --password-stdin
Calling the OpenFaaS server to validate the credentials...
Handling connection for 8080
credentials saved for admin http://127.0.0.1:8080
```

```sh
$ faas-cli list
Handling connection for 8080
Function                      	Invocations    	Replicas
nodeinfo                      	0              	2    
$ echo | faas-cli invoke nodeinfo
Handling connection for 8080
Hostname: nodeinfo-796f49f8ff-mdqcl

Platform: linux
Arch: x64
CPU count: 1
Uptime: 3730
```

FIXME: Anything else to demonstrate? 

## Cleanup

```sh
$ terraform destroy
$ cd ../../openfaas
$ terraform destroy
$ cd ../k8s-eks
$ terraform destroy
```

