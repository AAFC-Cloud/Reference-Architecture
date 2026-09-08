locals {
  storage_account_name = element(
    reverse(split("/", trim(var.storage_account_id, "/"))),
    0,
  )
}
