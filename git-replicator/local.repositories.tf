locals {
  # Keys include the project because repository names can repeat across projects.
  repositories = jsondecode(data.external.source.result.repositories)
}
