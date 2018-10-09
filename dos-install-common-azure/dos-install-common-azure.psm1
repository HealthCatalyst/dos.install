# Modules
Import-Module AzureRM
Import-Module AzureRM.Storage
Import-Module AzureRM.Profile

. $PSScriptRoot\functions\LoginToAzure.ps1

# KubernetesSecrets
. $PSScriptRoot\functions\KubernetesSecrets\CreateSecretWithMultipleValues.ps1
. $PSScriptRoot\functions\KubernetesSecrets\DeleteSecret.ps1

# Storage
. $PSScriptRoot\functions\Storage\GetStorageAccountName.ps1
. $PSScriptRoot\functions\Storage\SetStorageAccountNameIntoSecret.ps1

# LoadBalancer
. $PSScriptRoot\functions\LoadBalancer\SetupLoadBalancer.ps1