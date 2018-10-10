# Modules
Import-Module AzureRM
Import-Module AzureRM.Storage
Import-Module AzureRM.Profile
Import-Module AzureRM.Resources

Import-Module "..\dos-install-common-kube"

. $PSScriptRoot\functions\LoginToAzure.ps1

. $PSScriptRoot\functions\InstallStack.ps1

# arm
. $PSScriptRoot\functions\arm\DeployTemplate.ps1

# Subscription
. $PSScriptRoot\functions\Subscription\SetCurrentAzureSubscription.ps1

# Storage
. $PSScriptRoot\functions\Storage\GetStorageAccountName.ps1
. $PSScriptRoot\functions\Storage\SetStorageAccountNameIntoSecret.ps1

# LoadBalancer
. $PSScriptRoot\functions\LoadBalancer\SetupLoadBalancer.ps1