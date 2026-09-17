locals {
  pipeline_yaml_trigger_covers_directory = {
    for registration_file, expected_directory in local.pipeline_yaml_expected_directories :
    registration_file => anytrue([
      for suffix in ["/**", "/*"] : contains(
        local.pipeline_yaml_trigger_includes[registration_file],
        expected_directory == "." ? trimprefix(suffix, "/") : "${expected_directory}${suffix}"
      )
    ])
  }
}
