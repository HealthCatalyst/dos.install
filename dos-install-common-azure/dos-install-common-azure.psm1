# Modules
Import-Module AzureRM
Import-Module AzureRM.Storage
Import-Module AzureRM.Profile
Import-Module AzureRM.Resources
Import-Module AzureRM.Aks

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$here\..\dos-install-common-kube\dos-install-common-kube.psm1"


# $Path = "$PSScriptRoot\functions"
# Get-ChildItem -Path $Path -Filter *.ps1 |Where-Object { $_.FullName -ne $PSCommandPath } |ForEach-Object {
#     . $_.FullName
# }

. $PSScriptRoot\functions\LoginToAzure.ps1

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
. $PSScriptRoot\functions\Subscription\GetResourceGroup.ps1
. $PSScriptRoot\functions\Subscription\GetCurrentAzureSubscription.ps1

# Storage
. $PSScriptRoot\functions\Storage\GetStorageAccountName.ps1
. $PSScriptRoot\functions\Storage\SetStorageAccountNameIntoSecret.ps1
. $PSScriptRoot\functions\Storage\CreateShare.ps1
. $PSScriptRoot\functions\Storage\CreateShareInStorageAccount.ps1
. $PSScriptRoot\functions\Storage\DeleteShare.ps1
. $PSScriptRoot\functions\Storage\CreateAzureStorage.ps1

# LoadBalancer
. $PSScriptRoot\functions\LoadBalancer\SetupLoadBalancer.ps1
. $PSScriptRoot\functions\LoadBalancer\TestAzureLoadBalancer.ps1
. $PSScriptRoot\functions\LoadBalancer\GetUrlAndIPForLoadBalancer.ps1

# Network
. $PSScriptRoot\functions\Network\SetupNetworkSecurity.ps1

# Stack
. $PSScriptRoot\functions\Stack\InstallStackInAzure.ps1
. $PSScriptRoot\functions\Stack\CreateSecretsForStack.ps1
. $PSScriptRoot\functions\Stack\InstallProductInAzure.ps1
. $PSScriptRoot\functions\Stack\DeleteNamespaceAndData.ps1
. $PSScriptRoot\functions\Stack\RunRealtimeTester.ps1

# keyvault
. $PSScriptRoot\functions\KeyVault\CopyKubernetesSecretsToKeyVault.ps1
. $PSScriptRoot\functions\KeyVault\SaveKeyInVault.ps1
. $PSScriptRoot\functions\KeyVault\CreateKeyVault.ps1
. $PSScriptRoot\functions\KeyVault\Get-KeyVaultName.ps1
. $PSScriptRoot\functions\KeyVault\CopyKeyVaultSecretsToKubernetes.ps1
. $PSScriptRoot\functions\KeyVault\GetListOfSecretsInVault.ps1
. $PSScriptRoot\functions\KeyVault\GetKeyInVault.ps1

# Menus
. $PSScriptRoot\functions\Menus\ShowMainMenu.ps1
. $PSScriptRoot\functions\Menus\ShowProductMenu.ps1

# VirtualMachine
. $PSScriptRoot\functions\VirtualMachine\StartVMsInResourceGroup.ps1
. $PSScriptRoot\functions\VirtualMachine\StopVMsInResourceGroup.ps1
. $PSScriptRoot\functions\VirtualMachine\ShowSSHCommandsToVMs.ps1
. $PSScriptRoot\functions\VirtualMachine\RestartVMsInResourceGroup.ps1
. $PSScriptRoot\functions\VirtualMachine\GetPublicNameofMasterVM.ps1
