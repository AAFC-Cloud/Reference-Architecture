locals {
  pipeline_yaml_expected_directories = {
    for registration_file, yaml_path in local.pipeline_yaml_paths :
    registration_file => replace(dirname(yaml_path), "\\", "/")
  }
}
