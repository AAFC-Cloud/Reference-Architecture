locals {
  pipeline_authorizations = {
    for authorization in flatten([
      for pipeline_key, pipeline in local.pipelines : [
        for index, authorization in pipeline.authorizations : {
          key          = "${pipeline_key}-${index}"
          pipeline_key = pipeline_key
          type         = authorization.type
          resource_id = (
            authorization.type == "queue"
            ? data.azuredevops_agent_queue.main[authorization.name].id
            : authorization.type == "environment"
            ? data.azuredevops_environment.change_approval[authorization.name].id
            : data.azuredevops_serviceendpoint_azurerm.main[authorization.name].id
          )
        }
      ]
    ]) : authorization.key => authorization
  }
}
