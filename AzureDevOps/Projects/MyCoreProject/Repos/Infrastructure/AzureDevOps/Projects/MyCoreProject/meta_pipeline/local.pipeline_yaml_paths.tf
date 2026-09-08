locals {
  # A path beginning with ./ is relative to the registration file's directory.
  # Other paths remain repo-root-relative for backwards compatibility.
  pipeline_yaml_paths = {
    for registration_file, pipeline in local.pipeline_registrations :
    registration_file => replace(
      startswith(pipeline.yaml_path, "./")
      ? (
        dirname(registration_file) == "."
        ? trimprefix(pipeline.yaml_path, "./")
        : "${dirname(registration_file)}/${trimprefix(pipeline.yaml_path, "./")}"
      )
      : pipeline.yaml_path,
      "\\",
      "/"
    )
  }
}
