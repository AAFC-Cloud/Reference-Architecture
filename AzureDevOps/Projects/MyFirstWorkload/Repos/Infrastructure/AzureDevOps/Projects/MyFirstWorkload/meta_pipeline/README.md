# MyFirstWorkload meta-pipeline

This Terraform root belongs to MyFirstWorkload/Infrastructure. It scans only this repository for `.tfvars.pipeline_registration` files and manages the resulting pipeline definitions and per-pipeline queue, service-connection and environment authorizations in MyFirstWorkload.

Its registrations include the meta-pipeline itself, the approval environment and App Configuration. Paths and validation follow the same pattern as MyCoreProject's meta-pipeline. Add future workload registrations beside their Terraform roots.

The pipeline uses `MyFirstWorkload-ServiceConnection`, backed by `MyFirstWorkload-SP`, and stores its state in `teamymyfirstworkloadsa/statefiles`. Core creates the project, Entra identity, project permissions, Azure foundations and service connection. The workload owns its pipeline inventory and its meta-pipeline state.

## First run

Complete the Core onboarding pipelines and publish this Infrastructure repository first. The workload's project, application identity, service connection, Azure foundations, dedicated state account and container, and agent queue must exist.

First apply the workload-owned [approval environment](../environments/Main/README.md) locally once. This meta-pipeline looks up `MyFirstWorkload-DEV` when registering pipelines, so the environment must exist before its first plan.

Then, from this directory, use a local identity with access to the state container and administration permissions in MyFirstWorkload. Initialize Terraform, review a saved plan, and apply it once:

```powershell
terraform init
terraform validate
terraform plan -out=meta-bootstrap.tfplan
terraform show -no-color meta-bootstrap.tfplan
terraform apply meta-bootstrap.tfplan
```

This first apply creates and authorizes `pipeline definitions`, `MyFirstWorkload-DEV` and `Teamy-Workload-MyFirstWorkload-DEV-RG - workload - app_configuration` and records their ownership in this root's workload state.

Queue the meta-pipeline in MyFirstWorkload to confirm it works through `MyFirstWorkload-ServiceConnection`. Then queue App Configuration for its first deployment and approve its saved plan in `MyFirstWorkload-DEV`.

Normal changes to this root or any registration trigger the meta-pipeline. New pipeline definitions skip their first run until authorizations are in place. Avoid concurrent local and pipeline applies against this state.

## Local checks

```powershell
terraform init -backend=false
terraform validate
```

These commands validate the configuration without initializing the remote backend.
