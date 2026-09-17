locals {
  pipeline_yaml_validation_errors = {
    for registration_file, expected_directory in local.pipeline_yaml_expected_directories :
    registration_file => {
      yaml_path          = local.pipeline_yaml_paths[registration_file]
      expected_directory = expected_directory
      trigger_paths      = local.pipeline_yaml_trigger_includes[registration_file]
      path_in_repo       = local.pipeline_yaml_path_in_repo[registration_file]
      errors = concat(
        local.pipeline_yaml_trigger_covers_directory[registration_file]
        ? []
        : ["trigger.paths.include must include ${expected_directory}/** or ${expected_directory}/*"],
        local.pipeline_yaml_path_in_repo[registration_file] == null || local.pipeline_yaml_path_in_repo[registration_file] == expected_directory
        ? []
        : ["extends.parameters.pathInRepo must equal ${expected_directory}"]
      )
    }
    if !local.pipeline_yaml_trigger_covers_directory[registration_file] || (
      local.pipeline_yaml_path_in_repo[registration_file] != null && local.pipeline_yaml_path_in_repo[registration_file] != expected_directory
    )
  }
}
