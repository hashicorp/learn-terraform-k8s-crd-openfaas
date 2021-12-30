/*
Hitting: https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367
resource "kubernetes_manifest" "openfaas_fn_showcow" {
  depends_on = [kubernetes_namespace.openfaas-fn, helm_release.openfaas]
  manifest = yamldecode(file("${path.module}/functions/cows/cows.yaml"))
}
*/

// https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367#issuecomment-911322756
resource "kubectl_manifest" "openfaas_fn_showcow" {
  depends_on = [kubernetes_namespace.openfaas-fn, helm_release.openfaas]
  yaml_body  = file("${path.module}/functions/cows/cows.yaml")
}
