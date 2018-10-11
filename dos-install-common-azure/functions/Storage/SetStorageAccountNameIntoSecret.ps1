<#
  .SYNOPSIS
  SetStorageAccountNameIntoSecret
  
  .DESCRIPTION
  SetStorageAccountNameIntoSecret
  
  .INPUTS
  SetStorageAccountNameIntoSecret - The name of SetStorageAccountNameIntoSecret

  .OUTPUTS
  None
  
  .EXAMPLE
  SetStorageAccountNameIntoSecret

  .EXAMPLE
  SetStorageAccountNameIntoSecret


#>

# https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/?view=azurermps-6.9.0
# https://docs.microsoft.com/en-us/powershell/module/azurerm.storage/get-azurermstorageaccountkey?view=azurermps-6.9.0

#Requires -Modules AzureRM.Storage, AzureRM.Profile

function SetStorageAccountNameIntoSecret()
{
  [CmdletBinding()]
  param
  (
    [parameter (Mandatory = $true) ]
    [ValidateNotNullOrEmpty()]
    [string]
    $resourceGroup
    ,
    [parameter (Mandatory = $true) ]
    [ValidateNotNullOrEmpty()]
    [string]
    $customerid
  )

  Write-Verbose 'SetStorageAccountNameIntoSecret: Starting'

  [string] $storageAccountName = $(GetStorageAccountName -resourceGroup $resourceGroup).StorageAccountName
  Write-Verbose "StorageAccountName: [$storageAccountName]"

  [string] $storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroup -AccountName $storageAccountName).Value[0]
  
  Write-Verbose "Storagekey: [$storageKey]"

  Write-Verbose "Creating kubernetes secret for Azure Storage Account: azure-secret"
  [string] $secretname = "azure-secret"
  [string] $namespace = "default"

  DeleteSecret -secretname $secretname -namespace $namespace

  CreateSecretWithMultipleValues -secretname $secretname -namespace $namespace -secret1 "resourcegroup=${resourceGroup}" -secret2 "azurestorageaccountname=${storageAccountName}" -secret3 "azurestorageaccountkey=${storageKey}"
  
  Write-Verbose 'SetStorageAccountNameIntoSecret: Done'
}

Export-ModuleMember -Function "SetStorageAccountNameIntoSecret"