# MyFirstWorkload project

This root creates the private MyFirstWorkload Azure DevOps project and manages its human members. It runs in MyCoreProject using the bootstrap service connection and the existing self-hosted pool.

People follow MyCoreProject's existing pattern: edit [local.people.tf](./local.people.tf), resolve users through `data.azuredevops_users.main`, and use `local.people_with_descriptors` for memberships. Everyone listed belongs to the default project team. People marked `is_project_admin` are project administrators.

Default-team membership uses `overwrite`. Human administrator membership uses `add` because the [service connection's project-permissions root](<../service_connections/workload/devops_project_permissions/>) independently manages the deployment principal's membership in the same group. An overwrite here would remove that principal on later project applies.

Project creation has no dependency on the workload identity. The [service_connections/workload](<../service_connections/workload/>) roots handle identity licensing, project permissions, Azure RBAC and federation separately. The workload repository owns its approval environment and pipeline inventory.

The project has deletion protection. The initial people list contains the same existing Azure DevOps user as MyCoreProject; adapt it when adopting this example.
