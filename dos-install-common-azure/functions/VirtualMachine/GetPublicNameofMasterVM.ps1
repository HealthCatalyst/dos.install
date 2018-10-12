<#
.SYNOPSIS
GetPublicNameofMasterVM

.DESCRIPTION
GetPublicNameofMasterVM

.INPUTS
GetPublicNameofMasterVM - The name of GetPublicNameofMasterVM

.OUTPUTS
None

.EXAMPLE
GetPublicNameofMasterVM

.EXAMPLE
GetPublicNameofMasterVM


#>
function GetPublicNameofMasterVM() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'GetPublicNameofMasterVM: Starting'
    [hashtable]$Return = @{}

    $resourceGroupLocation = $(Get-AzureRmResourceGroup -Name "$resourceGroup").Location

    $masterVMName = "${resourceGroup}.${resourceGroupLocation}.cloudapp.azure.com"

    $Return.Name = $masterVMName
    Write-Verbose 'GetPublicNameofMasterVM: Done'
    return $Return
}

Export-ModuleMember -Function 'GetPublicNameofMasterVM'