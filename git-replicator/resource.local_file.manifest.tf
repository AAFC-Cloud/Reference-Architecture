resource "local_file" "manifest" {
  for_each = local.repository_manifests

  filename             = abspath("${path.module}/.terraform/manifests/${each.key}.json")
  content              = jsonencode(each.value)
  file_permission      = "0600"
  directory_permission = "0700"

  depends_on = [data.external.repository_status]
}
