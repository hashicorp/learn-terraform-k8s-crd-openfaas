output "self" {
  value = {
    terraform_workspace = terraform.workspace
    last_update         = timestamp()
  }
}
