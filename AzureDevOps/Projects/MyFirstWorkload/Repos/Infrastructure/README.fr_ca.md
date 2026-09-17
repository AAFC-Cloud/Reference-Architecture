# MyFirstWorkload

[English](./README.md)

Ce projet Azure DevOps possède le code Terraform et le pipeline de son premier déploiement : un magasin Azure App Configuration. L’équipe travaille directement dans ce dépôt Infrastructure.

Le projet de plateforme MyCoreProject établit le projet et ses membres, le groupe de ressources, l’identité de déploiement, la connexion de service fédérée et un compte de stockage d’état dédié avec un conteneur privé. Ce dépôt gère son environnement d’approbation et ses approbateurs, le code Terraform de son méta-pipeline, ses inscriptions de pipelines et son déploiement App Configuration.

| Paramètre | Valeur |
| --- | --- |
| Groupe de ressources | `Teamy-Workload-MyFirstWorkload-DEV-RG` |
| Identité de déploiement | `MyFirstWorkload-SP` (application Entra et principal de service) |
| Connexion de service | `MyFirstWorkload-ServiceConnection` |
| Environnement d’approbation | `MyFirstWorkload-DEV` |
| Pool d’agents | `Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-Pool` |
| État | `teamymyfirstworkloadsa` / `statefiles`, dans le groupe de ressources de la charge de travail |

L’identité possède le rôle Contributor sur son groupe de ressources, Storage Blob Data Contributor sur ce conteneur et l’appartenance à Project Administrators et Endpoint Administrators dans MyFirstWorkload. Son méta-pipeline peut ainsi gérer les définitions de pipelines et leurs autorisations dans ce projet. Elle ne reçoit aucun accès aux états des autres projets ni rôle d’administration à l’échelle de l’organisation.

Core crée le compte d’état selon le modèle du pool d’agents : mêmes paramètres de stockage, région et étiquettes du groupe de ressources de la charge de travail, et règles réseau copiées du compte d’amorçage au déploiement. Le sous-réseau des agents est ainsi autorisé sans inscrire les règles IP des opérateurs dans le dépôt. Core accorde aux deux identités de déploiement l’accès aux données blob du nouveau conteneur. Ces modules de la charge de travail utilisent le compte obtenu sans lire le compte d’amorçage ni l’état de Core.

Le [module racine App Configuration](<./AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Workload-MyFirstWorkload-DEV-RG/workload/app_configuration/>) crée un magasin de niveau Free dans la région Canada Central. Son nom comprend un hachage stable de l’identifiant du groupe de ressources pour distinguer les déploiements. L’authentification par clé d’accès est désactivée; les sorties contiennent seulement l’identifiant et le point de terminaison. Les futurs clients auront besoin de leurs propres rôles de données App Configuration. L’identité de la charge de travail ne récupère ni ne purge automatiquement les magasins supprimés de façon réversible.

Les commits sur main déclenchent le [pipeline](<./AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Workload-MyFirstWorkload-DEV-RG/workload/app_configuration/azure-pipelines.yml>). Il valide et planifie Terraform, puis applique le plan enregistré après l’approbation de l’environnement. Le projet possède sa propre copie du modèle de planification et d’application et de l’installateur; les exécutions ne dépendent donc pas d’une extraction du dépôt Core.

Le [méta-pipeline de la charge de travail](./AzureDevOps/Projects/MyFirstWorkload/meta_pipeline/) recherche les fichiers `.tfvars.pipeline_registration` dans ce dépôt Infrastructure. Il gère sa propre définition permanente, le [pipeline de l’environnement d’approbation](./AzureDevOps/Projects/MyFirstWorkload/environments/Main/) et le pipeline App Configuration, y compris leurs autorisations, avec sa propre clé d’état dans le conteneur de la charge de travail. Ajoutez les inscriptions ici au fil de l’évolution du projet. Le mécanisme Core gère seulement le dépôt Core.

Pour vérifier localement la syntaxe, exécutez les commandes suivantes dans le répertoire App Configuration :

```powershell
terraform init -backend=false
terraform validate
```

Ces vérifications ne déploient aucune ressource. Après le provisionnement des prérequis par Core et la publication du dépôt, suivez la [procédure initiale du méta-pipeline](./AzureDevOps/Projects/MyFirstWorkload/meta_pipeline/README.md#first-run). Appliquez localement le module de l’environnement une première fois, puis celui du méta-pipeline pour inscrire les pipelines; les changements suivants passent par les pipelines de ce projet.
