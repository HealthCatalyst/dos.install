<#
  .SYNOPSIS
  CreateAzureStorage

  .DESCRIPTION
  CreateAzureStorage

  .INPUTS
  CreateAzureStorage - The name of CreateAzureStorage

  .OUTPUTS
  None

  .EXAMPLE
  CreateAzureStorage

  .EXAMPLE
  CreateAzureStorage


#>
function CreateAzureStorage() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $namespace
    )

    Write-Verbose 'CreateAzureStorage: Starting'

    [hashtable]$Return = @{}

    AssertStringIsNotNullOrEmpty $namespace

    [string] $resourceGroup = $(GetResourceGroup).ResourceGroup

    Write-Information -MessageData "Using resource group: $resourceGroup"

    if ([string]::IsNullOrWhiteSpace($(kubectl get namespace $namespace --ignore-not-found=true))) {
        kubectl create namespace $namespace
    }

    [string] $shareName = "$namespace"

    CreateShare -resourceGroup $resourceGroup -sharename $shareName -deleteExisting $false
    CreateShare -resourceGroup $resourceGroup -sharename "${shareName}backups" -deleteExisting $false

    Write-Verbose 'CreateAzureStorage: Done'
    return $Return
}

Export-ModuleMember -Function "CreateAzureStorage"