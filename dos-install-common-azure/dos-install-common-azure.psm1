# Modules
Import-Module AzureRM
Import-Module AzureRM.Storage
Import-Module AzureRM.Profile
Import-Module AzureRM.Resources
Import-Module AzureRM.Aks

Import-Module "..\dos-install-common-kube"

. $PSScriptRoot\functions\LoginToAzure.ps1

. $PSScriptRoot\functions\InstallStack.ps1

. $PSScriptRoot\functions\Uninstall-AllModules.ps1

# arm
. $PSScriptRoot\functions\arm\AssignPermissionsToServicePrincipal.ps1
. $PSScriptRoot\functions\arm\BuildSubnetId.ps1
. $PSScriptRoot\functions\arm\CreateServicePrincipal.ps1
. $PSScriptRoot\functions\arm\CleanResourceGroup.ps1
. $PSScriptRoot\functions\arm\DeployTemplate.ps1
. $PSScriptRoot\functions\arm\GetConfigHashTable.ps1
. $PSScriptRoot\functions\arm\GetConfigObjectFromFile.ps1
. $PSScriptRoot\functions\arm\GetKeyVaultSecretValue.ps1
. $PSScriptRoot\functions\arm\StripJsonComments.ps1

# Subscription
. $PSScriptRoot\functions\Subscription\SetCurrentAzureSubscription.ps1

# Storage
. $PSScriptRoot\functions\Storage\GetStorageAccountName.ps1
. $PSScriptRoot\functions\Storage\SetStorageAccountNameIntoSecret.ps1

# LoadBalancer
. $PSScriptRoot\functions\LoadBalancer\SetupLoadBalancer.ps1