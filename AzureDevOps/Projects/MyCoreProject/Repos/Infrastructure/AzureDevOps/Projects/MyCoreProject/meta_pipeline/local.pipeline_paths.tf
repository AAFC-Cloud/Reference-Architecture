locals {
  # Keep Azure DevOps pipeline folders aligned with the repository directory
  # that contains each .tfvars.pipeline_registration file.
  pipeline_paths = {
    for pipeline_key in keys(local.pipelines) :
    pipeline_key => (
      dirname(pipeline_key) == "."
      ? "\\"
      : "\\${replace(dirname(pipeline_key), "/", "\\")}"
    )
  }
}
