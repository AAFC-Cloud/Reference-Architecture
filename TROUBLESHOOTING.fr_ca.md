# Dépannage

[English](./TROUBLESHOOTING.md) | [Présentation de l’architecture](./README.fr_ca.md) | [Maintenance de la référence](./MAINTENANCE.fr_ca.md)

Lorsqu’un pipeline échoue, notez le numéro d’exécution, l’étape en échec, le module racine Terraform et la connexion de service utilisée par cette étape. Une commande locale qui réussit peut utiliser une identité ou un chemin réseau différent de celui de l’agent.

Le [pipeline de vérification de l’état][healthcheck] vérifie les outils installés, Docker, l’accessibilité d’Azure DevOps, l’authentification Azure et la liste des objets blob. Il n’applique pas de configuration Terraform.

## Le fournisseur Azure DevOps signale `No valid credentials found`

Vérifiez l’URL d’organisation dans `provider.azuredevops.tf` et l’identité utilisée pour l’authentification. Pour une exécution locale, le dépôt permet de fournir un jeton d’accès personnel au moyen d’une variable d’environnement :

```powershell
$env:AZDO_PERSONAL_ACCESS_TOKEN = Read-Host -MaskInput 'Azure DevOps PAT'
```

Utilisez PowerShell 7 pour cette invite. L’identité du jeton doit posséder les autorisations requises par le module racine ciblé. Gardez le jeton hors des fichiers Terraform et des journaux, puis supprimez la variable de session lorsque vous avez terminé :

```powershell
Remove-Item Env:AZDO_PERSONAL_ACCESS_TOKEN
```

Dans un pipeline, vérifiez la connexion de service choisie et ses autorisations Azure DevOps. L’accès à l’abonnement Azure ne démontre pas à lui seul que l’identité peut gérer les ressources Azure DevOps. Le [modèle partagé][template] fournit les variables d’environnement du jeton de tâche pour la fédération d’identité de charge de travail.

## La validation des inscriptions de pipelines échoue

Le [méta-pipeline][meta] indique chaque fichier YAML concerné avec les valeurs attendues et les valeurs réelles. Vérifiez les fichiers indiqués :

- `yaml_path = "./azure-pipelines.yml"` est résolu à côté du fichier d’inscription.
- Chaque fichier YAML doit avoir une seule inscription.
- `trigger.paths.include` doit contenir le répertoire du pipeline suivi de `/**` ou de `/*`. Un motif plus large visant le répertoire parent ne satisfait pas le validateur actuel.
- `extends.parameters.pathInRepo`, lorsqu’il est présent, doit correspondre à ce répertoire.
- Les chemins sont relatifs au dépôt Azure DevOps de destination. Pour `Infrastructure`, omettez le préfixe externe `AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/`.

Fournissez aussi les paramètres obligatoires `agentPoolName`, `serviceConnectionName` et `environmentName` du modèle partagé. L’inscription doit contenir les autorisations `queue`, `endpoint` et `environment` correspondantes. La précondition sur les métadonnées vérifie les chemins et les doublons; elle ne vérifie pas tous les paramètres du modèle.

Après avoir corrigé les sources, publiez-les avec `git-replicator` et relancez le méta-pipeline.

## Un pipeline est absent, désactivé ou en attente

Un fichier YAML doit être accompagné d’un fichier `.tfvars.pipeline_registration`, puis le méta-pipeline doit être appliqué avec succès pour créer sa définition. Vérifiez que l’inscription a été publiée et que `enabled` est absent ou vaut `true`.

En cas d’erreur d’autorisation, confirmez l’existence de la file d’agents, de la connexion de service et de l’environnement nommés, puis vérifiez les autorisations de l’inscription. Pour une tâche en file d’attente, examinez la disponibilité des agents dans le pool configuré. L’amorçage doit être effectué à partir d’un poste de travail ou d’un agent existant jusqu’à ce que le nouveau pool soit disponible.

L’étape Apply peut attendre les vérifications d’approbation de l’environnement. Examinez l’artefact `terraform-plan`. Un plan sans modification saute volontairement l’étape Apply.

## L’accès à l’état Terraform échoue ou le stockage signale ses règles réseau

Avec `--auth-mode login`, l’appelant a besoin d’un rôle d’accès aux données blob, par exemple `Storage Blob Data Contributor`, sur le conteneur ou une portée englobante. Un rôle de gestion Azure comme Owner n’accorde pas à lui seul l’accès aux données blob par Microsoft Entra ID. Consultez les [rôles d’accès aux données blob Azure](https://learn.microsoft.com/en-us/azure/storage/blobs/assign-azure-role-data-access).

Exécutez ces vérifications en lecture seule à partir de l’environnement en échec, avec la même identité. Choisissez le compte indiqué dans le stockage distant du module racine; cet exemple vérifie l’état des charges de travail :

```powershell
$subscription = 'AAFC VSE Benefit'
$storageAccount = 'teamyhubazdoagentpool1sa'

az account show --subscription $subscription --query '{subscriptionId:id,tenantId:tenantId}' --output json
az storage blob list --subscription $subscription --account-name $storageAccount --container-name statefiles --auth-mode login --num-results 1 --only-show-errors --query '[].name' --output tsv
```

`az account show` utilise une API de gestion; sa réussite ne démontre pas l’accès aux objets blob. Vérifiez les attributions de rôles de données de l’identité réellement utilisée par le pipeline. Demandez au responsable de la ressource de confirmer l’accès prévu du sous-réseau sans partager la liste IP privée. Évitez les exports complets des propriétés du compte, les fichiers d’état et les sorties de plan qui pourraient exposer ces valeurs.

La [configuration du stockage des charges de travail][storage] copie volontairement les listes de contrôle d’accès réseau du compte d’amorçage préalable pour garder la liste IP hors des sources publiques. L’autorisation existante du sous-réseau des agents est consignée à partir de l’exemple expurgé du responsable dans le [guide de maintenance](./MAINTENANCE.fr_ca.md#intégrer-les-prérequis-à-ce-dépôt). Le sous-réseau doit avoir un point de terminaison de service Storage en plus de la règle correspondante sur le compte; consultez l’[accès réseau à Azure Storage](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security).

Après une modification des règles préalables, réappliquez la configuration du stockage des charges de travail pour la copier. Pour le déploiement initial, suivez l’[ordre d’amorçage local](./MAINTENANCE.fr_ca.md#amorçage-local-et-transfert-aux-agents) : le compte d’amorçage déjà restreint exige une machine locale autorisée jusqu’à ce que le pool auto-hébergé ait accès à l’état.

L’autorisation d’une adresse IP publique ne règle pas l’accès des clients Azure situés dans la même région que le compte de stockage; utilisez une règle de réseau virtuel et une configuration de point de terminaison appropriées. Consultez les [limites du pare-feu de stockage](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security-limitations).

Les modules racines d’amorçage utilisent `terraformproddwvc87`; les charges de travail utilisent `teamyhubazdoagentpool1sa`. Vérifiez le fichier `terraform.tf` du module en échec, y compris ses lectures d’état distant, plutôt que de présumer que les deux comptes offrent le même accès effectif.

## La vérification réseau Azure DevOps retourne HTTP 401 ou 403

La vérification PowerShell envoie une requête `HEAD` anonyme. HTTP 401 signifie que le serveur a répondu et exige une authentification; HTTP 403 signifie que l’accès a été refusé.

L’étape actuelle utilise [`-SkipHttpErrorCheck`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest#-skiphttperrorcheck) pour examiner la réponse. Elle accepte les codes 2xx, 401 et 403 comme résultats d’accessibilité et affiche le code reçu. Les erreurs de connexion et les codes HTTP inattendus font toujours échouer l’étape.

Cette vérification ne valide pas les autorisations Azure DevOps. Examinez les identifiants et les autorisations lorsqu’un fournisseur ou un appel d’API authentifié échoue. Les vérifications Bash et Docker utilisent des requêtes `curl` distinctes; consultez le journal de l’étape en échec pour les diagnostiquer.

## La création d’une image Marketplace échoue

Lisez le détail du message `ResourcePurchaseValidationFailed` :

| Détail de l’erreur | Mesure à prendre |
| --- | --- |
| Les conditions n’ont pas été acceptées | Vérifiez l’éditeur, l’offre, la référence SKU et le plan dans [`marketplace-image.json`][image]. Pour une image exigeant un plan, examinez les conditions avec [`accept-marketplace-agreement.ps1`][accept] avant de les accepter. |
| Le mode de paiement n’est pas pris en charge | L’abonnement n’a pas pu acheter cette offre. Accepter les conditions de nouveau ne corrige pas cet échec de validation de l’achat. Utilisez une image que l’abonnement permet de déployer. |

L’image configurée est Canonical Ubuntu 24.04 LTS (`Canonical:ubuntu-24_04-lts:server:latest`) avec `plan: null`. Elle omet la lecture de l’entente et le bloc de plan d’achat de la machine virtuelle. Le [fichier JSON CIS][cis-example] est un autre exemple, pas la sélection d’image active.

Pour les images avec un plan, la [source de données Terraform][agreement] vérifie que l’entente est acceptée. Le script effectue l’acceptation séparément. [`unaccept-marketplace-agreement.ps1`][unaccept] annule l’acceptation pour le plan et l’abonnement configurés; vérifiez ces valeurs avant de l’utiliser.

## Cloud-init ou une vérification Internet de la machine virtuelle échoue

Exécutez ces commandes dans le [répertoire `workload/vm_image`][vm-image], après avoir initialisé son stockage d’état distant et créé la machine virtuelle :

```powershell
terraform output -raw vm_id
./wait-for-cloudinit.ps1
```

Le script lit l’identifiant de ressource de la machine virtuelle dans les sorties Terraform, attend cloud-init, puis appelle `check-vm-internet.ps1`. Si `vm_id` est absent, l’état sélectionné n’expose pas cette sortie; vérifiez le répertoire de travail, le stockage d’état distant et l’application précédente.

Le script de vérification Internet affiche des messages distincts `vm | ...` et `docker | ...`. Examinez la sortie standard et la sortie d’erreur, y compris les messages de téléchargement d’image Docker. Il attend des résultats Azure Run Command portant le code `ProvisioningState/succeeded`; examinez aussi la sortie du système invité et les champs d’erreur de cloud-init.

Les vérifications actuelles de connectivité Docker utilisent `-k` / `--insecure`. Une vérification Docker réussie ne valide donc pas la chaîne de certificats. En cas d’erreur de certificat dans d’autres commandes, vérifiez la configuration de confiance de l’hôte et du conteneur; des [références sur les certificats][certificates] accompagnent les scripts de l’image.

## Maintenance du dépôt de référence

Pour les [échecs de réplication Git](./MAINTENANCE.fr_ca.md#la-réplication-git-échoue-ou-publie-des-fichiers-inattendus), la sélection des fichiers sources, la migration des ressources par fichier ou les [problèmes de chemins de copie de travail sous Windows](./MAINTENANCE.fr_ca.md#les-chemins-ou-les-opérations-sur-les-répertoires-échouent-sous-windows), consultez le guide de maintenance. Ces procédures concernent ce monodépôt de référence et son processus de publication.

[meta]: ./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureDevOps/Projects/MyCoreProject/meta_pipeline/
[template]: ./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/pipeline-templates/terraform-plan-and-apply/azure-pipelines.yml
[healthcheck]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/pipeline_healthcheck/azure-pipelines.yml>
[storage]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/core/state_file_storage_account/resource.azapi_resource.storage_account.tf>
[vm-image]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/>
[image]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/marketplace-image.json>
[cis-example]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/marketplace-image.cis-example.json>
[agreement]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/data.azurerm_marketplace_agreement.main.tf>
[accept]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/accept-marketplace-agreement.ps1>
[unaccept]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/unaccept-marketplace-agreement.ps1>
[certificates]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/cloud_init/CERTS.md>
