This Terraform dir is responsible for creating all the Azure DevOps pipelines that deploy the rest of the Terraform code.
This dir looks up the Azure DevOps environments that are used by those pipelines, so those environments must already exist before this dir is applied.
See [deploy-from-local.ps1](./deploy-from-local.ps1)

Pipeline registration files support an optional `enabled` setting. It defaults to
`true`; set `enabled = false` to disable the Azure DevOps pipeline without
removing its registration.
