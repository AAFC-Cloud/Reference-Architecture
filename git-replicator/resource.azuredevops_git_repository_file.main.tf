resource "azuredevops_git_repository_file" "main" {
  for_each = local.files

  repository_id       = azuredevops_git_repository.main[each.value.repository_key].id
  file                = each.value.repository_path
  content             = file("${local.source_root}/${each.value.source_path}")
  branch              = "refs/heads/main"
  commit_message      = "Replicate ${each.value.repository_path} from Reference-Architecture [skip ci]"
  overwrite_on_create = true
}
