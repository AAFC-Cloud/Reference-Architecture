# Subscription resource provider registrations

This Core root manages subscription-level provider registrations under the subscription directory, separately from resource groups and identity permissions. It registers Microsoft.AppConfiguration in AAFC VSE Benefit using the bootstrap connection.

Azure exposes provider namespace information even before registration. This Terraform resource manages the subscription's registration, and [AzureRM requires an import when the registration is already `Registered`](https://github.com/hashicorp/terraform-provider-azurerm/blob/main/internal/services/resource/resource_provider_registration_resource.go).

Microsoft.AppConfiguration is already registered in this reference subscription. The import block adopts that registration into this root's state through the normal pipeline plan/apply. It can remain after the import; subsequent runs use the managed resource. When adapting this root to a subscription where the provider is not registered, omit the import block so the resource can register it; AzureRM only imports registered providers.

Complete this pipeline before deploying MyFirstWorkload's App Configuration store. The workload identity retains Contributor at its resource group and does not need subscription-level registration permissions. The registration is protected from deletion.
