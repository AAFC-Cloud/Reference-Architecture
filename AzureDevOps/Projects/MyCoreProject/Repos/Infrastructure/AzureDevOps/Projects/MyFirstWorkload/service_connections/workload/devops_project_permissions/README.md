# MyFirstWorkload Azure DevOps project permissions

This follows MyCoreProject's separate `devops_project_permissions` root. It adds the onboarded MyFirstWorkload-SP principal to Project Administrators and Endpoint Administrators within MyFirstWorkload.

Run the [project](<../../../project/>), [Entra identity](<../../../../../../Entra/AppRegistrations/MyFirstWorkload-SP/>) and [Azure DevOps licensing](<../devops_license/>) roots first. Membership uses `add` so this root manages only its service principal and preserves human members managed by the project root.

The workload's own meta-pipeline uses these project permissions to manage pipeline definitions and resource authorizations. No organization administrator role is granted.
