locals {
  pipeline_yaml_path_in_repo = {
    for registration_file, yaml in local.pipeline_yaml_documents :
    registration_file => try(
      trimsuffix(
        trimprefix(
          replace(yaml.extends.parameters.pathInRepo, "\\", "/"),
          "./"
        ),
        "/"
      ),
      null
    )
  }
}
