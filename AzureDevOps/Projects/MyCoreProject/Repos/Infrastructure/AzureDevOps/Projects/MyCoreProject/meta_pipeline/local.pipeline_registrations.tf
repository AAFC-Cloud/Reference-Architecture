locals {
  pipeline_registrations = {
    for registration_file in local.pipeline_registration_files :
    registration_file => provider::terraform::decode_tfvars(
      file("${local.repository_root}/${registration_file}")
    )
  }
}
