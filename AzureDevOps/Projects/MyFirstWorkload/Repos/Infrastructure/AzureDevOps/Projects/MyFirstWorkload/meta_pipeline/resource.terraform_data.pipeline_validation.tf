# Validate the registrations once so each pipeline does not repeat the same report.
resource "terraform_data" "pipeline_validation" {
  lifecycle {
    precondition {
      condition = length(local.duplicate_pipeline_yaml_paths) == 0 && length(local.pipeline_yaml_validation_errors) == 0
      error_message = join("\n\n", concat(
        ["Pipeline registration validation failed. Review the following files:"],
        local.pipeline_validation_messages
      ))
    }
  }
}
