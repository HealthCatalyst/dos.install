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
    [ValidateNotNull()]
    [string]
    $resourceGroup
    ,
    [parameter (Mandatory = $true) ]
    [ValidateNotNull()]
    [string]
    $customerid
  )

  Write-Verbose 'SetStorageAccountNameIntoSecret: Starting'

  Write-Verbose "Resource Group: $resourceGroup"
  Write-Verbose "CustomerID: $customerid"

  $storageAccountName = $(GetStorageAccountName -resourceGroup $resourceGroup).StorageAccountName
  Write-Verbose "StorageAccountName: [$storageAccountName]"

  $storageKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroup -AccountName $storageAccountName).Value[0]
  
  Write-Verbose "Storagekey: [$storageKey]"

  Write-Host "Creating kubernetes secret for Azure Storage Account: azure-secret"
  $secretname = "azure-secret"
  $namespace = "default"

  DeleteSecret -secretname $secretname -namespace $namespace

  CreateSecretWithMultipleValues -secretname $secretname -namespace $namespace -secret1 "resourcegroup=${resourceGroup}" -secret2 "azurestorageaccountname=${storageAccountName}" -secret3 "azurestorageaccountkey=${storageKey}"
  
  Write-Verbose 'SetStorageAccountNameIntoSecret: Done'
}

Export-ModuleMember -Function "SetStorageAccountNameIntoSecret"