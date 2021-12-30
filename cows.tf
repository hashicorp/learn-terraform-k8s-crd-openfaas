resource "kubernetes_manifest" "openfaas_fn_showcow" {
  depends_on = [kubernetes_namespace.openfaas, helm_release.openfaas]
  manifest = yamldecode(file("${path.module}/functions/cows/cows.yaml"))
}
