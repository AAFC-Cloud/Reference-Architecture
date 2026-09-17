# MyFirstWorkload service connection

This follows MyCoreProject's `service_connections/bootstrap/service_connection` root. It creates MyFirstWorkload-ServiceConnection in the existing workload project and attaches a federated identity credential to the [Entra application](<../../../../../../Entra/AppRegistrations/MyFirstWorkload-SP/>).

The identity exports the same `application_client_id`, `application_object_id` and `service_principal_object_id` contract as the bootstrap identity. The connection uses the client ID; federation uses the application resource ID exported as `application_object_id`. Subscription metadata comes from the AzureRM client and subscription data sources.

Run the [project](<../../../project/>) and Entra identity pipelines first. This root runs through MyCoreProject's bootstrap connection, whose principal owns the application. It creates no client secret.

The sibling [devops_project_permissions](<../devops_project_permissions/>) and [azure_rbac](<../azure_rbac/>) roots supply the deployment permissions. Complete all prerequisites before bootstrapping the workload environment and meta-pipeline in MyFirstWorkload/Infrastructure.
