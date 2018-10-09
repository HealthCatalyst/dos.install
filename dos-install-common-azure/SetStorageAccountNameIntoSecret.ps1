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

Import-Module AzureRM

function SetStorageAccountNameIntoSecret()
{
  [CmdletBinding()]
  param
  (
    [parameter (Mandatory = $true) ]
    [ValidateNotNull()]
    $config
  )

  Write-Verbose 'SetStorageAccountNameIntoSecret: Starting'

  $resourceGroup = $($config.azure.resourceGroup)
  Write-Host "Resource Group: $resourceGroup"
  $customerid = $($config.customerid)
  Write-Host "CustomerID: $customerid"

  $storageAccountName = $(GetStorageAccountName -resourceGroup $resourceGroup).StorageAccountName

  Write-Host "Get storage account key"
  $storageKey = az storage account keys list --resource-group $resourceGroup --account-name $storageAccountName --query "[0].value" --output tsv

  # Write-Host "Storagekey: [$STORAGE_KEY]"

  Write-Host "Creating kubernetes secret for Azure Storage Account: azure-secret"
  $secretname = "azure-secret"
  $namespace = "default"
  if (![string]::IsNullOrWhiteSpace($(kubectl get secret $secretname -n $namespace -o jsonpath='{.data}' --ignore-not-found=true))) {
      kubectl delete secret $secretname -n $namespace
  }
  kubectl create secret generic $secretname -n $namespace --from-literal=resourcegroup="${resourceGroup}" --from-literal=azurestorageaccountname="${storageAccountName}" --from-literal=azurestorageaccountkey="${storageKey}"

  Write-Verbose 'SetStorageAccountNameIntoSecret: Done'

}

Export-ModuleMember -Function "SetStorageAccountNameIntoSecret"