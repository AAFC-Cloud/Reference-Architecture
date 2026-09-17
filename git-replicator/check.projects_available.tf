check "projects_available" {
  assert {
    condition = length(local.deferred_projects) == 0
    error_message = format(
      "Deferring replication for projects not yet ready or not visible to this identity: %s. Their repositories and files will not be published in this run. Deploy the projects through Core (or restore project access), then run the replicator again.",
      join(", ", sort(tolist(local.deferred_projects)))
    )
  }
}
