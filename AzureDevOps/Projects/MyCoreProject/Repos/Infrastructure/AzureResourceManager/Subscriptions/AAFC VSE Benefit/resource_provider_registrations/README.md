# Subscription resource provider registrations

This Core root manages subscription-level provider registrations under the subscription directory, separately from resource groups and identity permissions. It registers Microsoft.AppConfiguration in AAFC VSE Benefit using the bootstrap connection.

Complete this pipeline before deploying MyFirstWorkload's App Configuration store. The workload identity retains Contributor at its resource group and does not need subscription-level registration permissions. The registration is protected from deletion.
