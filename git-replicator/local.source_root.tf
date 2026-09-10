locals {
  source_root = abspath(coalesce(var.source_root, "${path.module}/.."))
}
