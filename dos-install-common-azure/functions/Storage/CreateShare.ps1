<#
  .SYNOPSIS
  CreateShare

  .DESCRIPTION
  CreateShare

  .INPUTS
  CreateShare - The name of CreateShare

  .OUTPUTS
  None

  .EXAMPLE
  CreateShare

  .EXAMPLE
  CreateShare


#>
function CreateShare() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $sharename
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $deleteExisting
    )

    Write-Verbose 'CreateShare: Starting'

    [hashtable]$Return = @{}

    $storageAccountName = ReadSecretData -secretname azure-secret -valueName azurestorageaccountname

    CreateShareInStorageAccount -storageAccountName $storageAccountName -resourceGroup $resourceGroup -sharename $sharename -deleteExisting $deleteExisting

    Write-Verbose 'CreateShare: Done'
    return $Return
}

function CreateShareInStorageAccount() {

}


Export-ModuleMember -Function "CreateShare"