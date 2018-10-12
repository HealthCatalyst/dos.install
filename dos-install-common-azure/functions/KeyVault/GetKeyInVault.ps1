<#
.SYNOPSIS
GetKeyInVault

.DESCRIPTION
GetKeyInVault

.INPUTS
GetKeyInVault - The name of GetKeyInVault

.OUTPUTS
None

.EXAMPLE
GetKeyInVault

.EXAMPLE
GetKeyInVault


#>
function GetKeyInVault() {
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
        $key
    )

    Write-Verbose 'GetKeyInVault: Starting'

    [hashtable]$Return = @{}

    [string] $keyvaultname = $(Get-KeyVaultName -resourceGroup $resourceGroup).Name

    $Return.Value = $(Get-AzureKeyVaultSecret -VaultName "$keyvaultname" -Name "$key").SecretValueText

    Write-Verbose "GetKeyInVault: Done [$key]"
    return $Return
}

Export-ModuleMember -Function 'GetKeyInVault'