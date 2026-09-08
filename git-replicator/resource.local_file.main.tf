resource "local_file" "main" {
  for_each = local.files

  filename             = "${local.clone_root}/${each.value.repository_key}/${each.value.repository_path}"
  content_base64       = filebase64("${local.source_root}/${each.value.source_path}")
  file_permission      = each.value.git_mode == "100755" ? "0755" : "0644"
  directory_permission = "0755"

  # Prepare Git metadata and clear obsolete paths before writing the snapshot.
  depends_on = [terraform_data.prepare]
}
