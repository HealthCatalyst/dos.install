<#
.SYNOPSIS
CreateKeyVault

.DESCRIPTION
CreateKeyVault

.INPUTS
CreateKeyVault - The name of CreateKeyVault

.OUTPUTS
None

.EXAMPLE
CreateKeyVault

.EXAMPLE
CreateKeyVault


#>
function CreateKeyVault() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'CreateKeyVault: Starting'

    [hashtable]$Return = @{}

    [string] $keyvaultname = $(Get-KeyVaultName -resourceGroup $resourceGroup).Name

    [string] $location = $(Get-AzureRmResourceGroup -Name "$resourceGroup").Location

    $result = $(Get-AzureRMKeyVault -VaultName "$keyvaultname" -ResourceGroupName "$resourceGroup")
    if (!$result) {
        Write-Verbose "Creating keyvault: $keyvaultname"
        New-AzureRmKeyVault -VaultName "$keyvaultname" -ResourceGroupName "$resourceGroup" -Location "$location"
    }
    else {
        Write-Verbose "keyvault $keyvaultname exists so no need to create"
    }

    Write-Verbose 'CreateKeyVault: Done'
    Return $Return
}

Export-ModuleMember -Function 'CreateKeyVault'