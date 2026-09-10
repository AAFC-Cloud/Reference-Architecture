locals {
  # Read the registered pipeline YAML files so their repository metadata can
  # be checked during terraform plan. This catches copy/paste errors where a
  # pipeline still triggers, or runs Terraform from, another pipeline's path.
  pipeline_yaml_documents = {
    for registration_file, yaml_path in local.pipeline_yaml_paths :
    registration_file => yamldecode(
      file("${local.repository_root}/${yaml_path}")
    )
  }
}
