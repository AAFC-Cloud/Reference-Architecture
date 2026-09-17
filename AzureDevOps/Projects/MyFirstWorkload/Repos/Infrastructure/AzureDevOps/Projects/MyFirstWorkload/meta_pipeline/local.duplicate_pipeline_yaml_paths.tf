locals {
  duplicate_pipeline_yaml_paths = {
    for yaml_path in toset(values(local.pipeline_yaml_paths)) :
    yaml_path => [
      for registration_file in keys(local.pipeline_registrations) :
      registration_file
      if local.pipeline_yaml_paths[registration_file] == yaml_path
    ]
    if length([
      for candidate in values(local.pipeline_yaml_paths) :
      candidate
      if candidate == yaml_path
    ]) > 1
  }
}
