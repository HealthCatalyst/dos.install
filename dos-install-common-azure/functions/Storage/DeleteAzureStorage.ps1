<#
.SYNOPSIS
DeleteAzureStorage

.DESCRIPTION
DeleteAzureStorage

.INPUTS
DeleteAzureStorage - The name of DeleteAzureStorage

.OUTPUTS
None

.EXAMPLE
DeleteAzureStorage

.EXAMPLE
DeleteAzureStorage


#>
function DeleteAzureStorage() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $namespace
    )

    Write-Verbose 'DeleteAzureStorage: Starting'
    [hashtable]$Return = @{}

    if ([string]::IsNullOrWhiteSpace($namespace)) {
        Write-Error "no parameter passed to DeleteAzureStorage"
        exit
    }

    $resourceGroup = $(GetResourceGroup).ResourceGroup

    Write-Information -MessageData "Using resource group: $resourceGroup"

    $shareName = "$namespace"
    $storageAccountName = ReadSecretData -secretname azure-secret -valueName "azurestorageaccountname"

    $storageAccountConnectionString = az storage account show-connection-string -n $storageAccountName -g $resourceGroup -o tsv

    Write-Information -MessageData "deleting the file share: $shareName"
    DeleteShare -sharename $sharename -storageAccountConnectionString $storageAccountConnectionString
    Write-Verbose 'DeleteAzureStorage: Done'
    return $Return

}

Export-ModuleMember -Function 'DeleteAzureStorage'