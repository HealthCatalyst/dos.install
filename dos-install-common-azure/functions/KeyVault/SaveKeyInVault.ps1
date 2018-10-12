<#
.SYNOPSIS
SaveKeyInVault

.DESCRIPTION
SaveKeyInVault

.INPUTS
SaveKeyInVault - The name of SaveKeyInVault

.OUTPUTS
None

.EXAMPLE
SaveKeyInVault

.EXAMPLE
SaveKeyInVault


#>
function SaveKeyInVault() {
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
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $value
    )

    Write-Verbose 'SaveKeyInVault: Starting'

    [string] $keyvaultname = $(Get-KeyVaultName -resourceGroup $resourceGroup).Name

    $Secret = ConvertTo-SecureString -String "$value" -AsPlainText -Force
    Set-AzureKeyVaultSecret -VaultName "$keyvaultname" -Name "$key" -SecretValue $Secret

    Write-Verbose 'SaveKeyInVault: Done'
}

Export-ModuleMember -Function 'SaveKeyInVault'