variable "k8s_host" {
  description = "The hostname (in form of URI) of the Kubernetes API."
  type        = string
}

variable "k8s_client_certificate" {
  description = "PEM-encoded client certificate for TLS authentication."
  type        = string
}

variable "k8s_client_key" {
  description = "PEM-encoded client certificate key for TLS authentication."
  type        = string
}

variable "k8s_cluster_ca_certificate" {
  description = "PEM-encoded root certificates bundle for TLS authentication."
  type        = string
}
