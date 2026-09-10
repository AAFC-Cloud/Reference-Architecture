locals {
  agent_queue_names = toset([
    for authorization in flatten([
      for pipeline in local.pipelines : pipeline.authorizations
    ]) : authorization.name
    if authorization.type == "queue"
  ])
}
