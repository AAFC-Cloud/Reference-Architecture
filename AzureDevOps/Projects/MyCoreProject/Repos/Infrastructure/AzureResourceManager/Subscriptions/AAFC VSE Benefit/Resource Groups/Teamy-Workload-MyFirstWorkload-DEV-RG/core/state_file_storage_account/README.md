# MyFirstWorkload state storage account

This Core root follows the agent-pool's `core/state_file_storage_account` pattern. It creates `teamymyfirstworkloadsa` in `Teamy-Workload-MyFirstWorkload-DEV-RG` and a private `statefiles` container. The account inherits the resource group's location and tags.

The AzAPI resource uses the same StorageV2 / Standard_LRS configuration, TLS requirement and access settings as the agent-pool account. At deployment time, its data source reads `properties.networkAcls` from `terraformproddwvc87` and copies those rules, excluding `ipv6Rules` to retain schema validation. The bootstrap account's agent-subnet rule supplies the new account's network allowlist entry. Operator IP rules stay out of source files.

This root grants Storage Blob Data Contributor on the new container to MyFirstWorkload-SP and the Core bootstrap principal. It consumes their Entra remote-state outputs; the workload uses its application service principal in place of the agent-pool example's managed identity.

Deploy the workload resource group and Entra identity first. The bootstrap identity, storage account and network rules must already exist. Complete this root before bootstrapping the workload environment and meta-pipeline. A local bootstrap operator also needs data access to the new container.

This Core root keeps its own state on `terraformproddwvc87/statefiles`. The workload environment, meta-pipeline and App Configuration roots store their state on `teamymyfirstworkloadsa/statefiles`. Both the new account and container have deletion protection.
