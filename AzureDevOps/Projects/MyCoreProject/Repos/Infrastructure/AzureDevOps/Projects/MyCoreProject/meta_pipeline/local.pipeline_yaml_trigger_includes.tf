locals {
  pipeline_yaml_trigger_includes = {
    for registration_file, yaml in local.pipeline_yaml_documents :
    registration_file => try(
      tolist(yaml.trigger.paths.include),
      [yaml.trigger.paths.include],
      []
    )
  }
}
