locals {
  pipeline_yaml_duplicate_parameter_names = {
    for registration_file, document in local.pipeline_yaml_documents :
    registration_file => distinct([
      for parameter_name in [
        for parameter in try(document.parameters, []) : try(parameter.name, "")
      ] : parameter_name
      if parameter_name != "" && length([
        for candidate_name in [
          for parameter in try(document.parameters, []) : try(parameter.name, "")
        ] : candidate_name
        if candidate_name == parameter_name
      ]) > 1
    ])
  }
}
