<#
.SYNOPSIS
Get-KeyVaultName

.DESCRIPTION
Get-KeyVaultName

.INPUTS
Get-KeyVaultName - The name of Get-KeyVaultName

.OUTPUTS
None

.EXAMPLE
Get-KeyVaultName

.EXAMPLE
Get-KeyVaultName


#>
function Get-KeyVaultName() {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'Get-KeyVaultName: Starting'
    [hashtable]$Return = @{}

    [string] $keyvaultname = "${resourceGroup}keyvault"
    $keyvaultname = $keyvaultname -replace '[^a-zA-Z0-9]', ''
    $keyvaultname = $keyvaultname.ToLower()
    if ($keyvaultname.Length -gt 24) {
        $keyvaultname = $keyvaultname.Substring(0, 24) # azure does not allow names longer than 24
    }

    $Return.Name = $keyvaultname
    Write-Verbose "Get-KeyVaultName: Done [$keyvaultname]"
    return $Return
}

Export-ModuleMember -Function 'Get-KeyVaultName'