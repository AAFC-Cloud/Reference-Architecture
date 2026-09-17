# MyFirstWorkload Azure DevOps licensing

This root follows MyCoreProject's `service_connections/bootstrap/devops_license` pattern. It onboards the existing MyFirstWorkload-SP service principal into the Azure DevOps organization using the Core bootstrap connection.

Run the [Entra identity](<../../../../../../Entra/AppRegistrations/MyFirstWorkload-SP/>) pipeline first. This root reads its service-principal object ID from remote-state outputs and creates the entitlement. It can run before the workload project exists.

The sibling [devops_project_permissions](<../devops_project_permissions/>) root grants project membership after the project and entitlement exist. Federation is managed by the sibling [service_connection](<../service_connection/>) root.
