locals {
  pipeline_validation_messages = concat(
    [
      for yaml_path, registrations in local.duplicate_pipeline_yaml_paths : join("\n", concat(
        [
          "YAML: ${yaml_path}",
          "  Duplicate yaml_path: each YAML file must have only one registration.",
          "  Registered by:",
        ],
        [for registration in registrations : "    - ${registration}"]
      ))
    ],
    [
      for registration_file, failure in local.pipeline_yaml_validation_errors : join("\n", concat(
        ["YAML: ${failure.yaml_path}"],
        local.pipeline_yaml_trigger_covers_directory[registration_file] ? [] : concat(
          [
            "  trigger.paths.include:",
            "    Expected at least one of:",
            "      - ${failure.expected_directory == "." ? "**" : "${failure.expected_directory}/**"}",
            "      - ${failure.expected_directory == "." ? "*" : "${failure.expected_directory}/*"}",
            "    Actual:",
          ],
          length(failure.trigger_paths) == 0
          ? ["      (none)"]
          : [for trigger_path in failure.trigger_paths : "      - ${trigger_path == null ? "(null)" : trigger_path}"]
        ),
        failure.path_in_repo == null || failure.path_in_repo == failure.expected_directory ? [] : [
          "  extends.parameters.pathInRepo:",
          "    Expected: ${failure.expected_directory}",
          "    Actual:   ${failure.path_in_repo}",
        ],
        length(failure.duplicate_parameter_names) == 0 ? [] : [
          "  parameters:",
          "    Duplicate parameter name(s): ${join(", ", failure.duplicate_parameter_names)}",
        ]
      ))
    ]
  )
}
