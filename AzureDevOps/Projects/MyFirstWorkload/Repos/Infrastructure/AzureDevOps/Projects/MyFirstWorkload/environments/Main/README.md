# MyFirstWorkload approval environment

This workload-owned root creates `MyFirstWorkload-DEV` and its Terraform plan approval check. Edit [local.people.tf](./local.people.tf) to choose approvers independently of Core's project-member list.

The project, deployment identity, service connection and state storage account must already exist. State uses its own key in `teamymyfirstworkloadsa/statefiles`; this root does not read Core's remote state.

Apply this root locally once before bootstrapping the [meta-pipeline](../../meta_pipeline/README.md#first-run), because pipeline registration looks up the environment. From this directory, using an identity with project administration and state-container access:

```powershell
terraform init
terraform validate
terraform plan -out=environment-bootstrap.tfplan
terraform show -no-color environment-bootstrap.tfplan
terraform apply environment-bootstrap.tfplan
```

The workload meta-pipeline then registers `MyFirstWorkload-DEV`. Subsequent changes use the workload service connection and approval environment through that pipeline.
