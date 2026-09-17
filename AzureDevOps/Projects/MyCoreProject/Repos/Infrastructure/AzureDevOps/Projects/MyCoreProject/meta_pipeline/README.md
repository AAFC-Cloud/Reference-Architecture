This Terraform root discovers registrations in MyCoreProject/Infrastructure and manages that project's Azure DevOps pipelines. MyCoreProject provisions workload projects and their identities; each workload project's Infrastructure repository contains its own meta-pipeline Terraform and registrations.
This dir looks up the Azure DevOps environments that are used by those pipelines, so those environments must already exist before this dir is applied.
See [deploy-from-local.ps1](./deploy-from-local.ps1)

Pipeline registration files support an optional `enabled` setting. It defaults to
`true`; set `enabled = false` to disable the Azure DevOps pipeline without
removing its registration.
