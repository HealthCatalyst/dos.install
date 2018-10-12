<#
.SYNOPSIS
GetListOfSecretsInVault

.DESCRIPTION
GetListOfSecretsInVault

.INPUTS
GetListOfSecretsInVault - The name of GetListOfSecretsInVault

.OUTPUTS
None

.EXAMPLE
GetListOfSecretsInVault

.EXAMPLE
GetListOfSecretsInVault


#>
function GetListOfSecretsInVault() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'GetListOfSecretsInVault: Starting'

    [hashtable]$Return = @{}
    $Return.Secrets = @()

    [string] $keyvaultname = $(Get-KeyVaultName -resourceGroup $resourceGroup).Name

    [string[]] $secretids = $(Get-AzureKeyVaultSecret -VaultName $keyvaultname).Id
    foreach ($secretid in $secretids) {
        [string]$secretname = $secretid.SubString($secretid.LastIndexOf("/") + 1, $secretid.Length - 1 - $secretid.LastIndexOf("/"))
        [string] $secretvaluejson = $(GetKeyInVault -resourceGroup $resourceGroup -key $secretname).Value
        [string[]] $secretparts = $($secretname -split "00");
        if ($secretparts[0] -eq "kubernetes") {
            $secretvalue = $($secretvaluejson | ConvertFrom-Json)
            if ($secretvalue -is [array]) {
                $Return.Secrets += @{
                    namespace    = $secretparts[1]
                    secretname   = $secretparts[2]
                    secretkey    = $secretparts[3]
                    secretvalues = $secretvalue
                }
            }
            else {
                $Return.Secrets += @{
                    namespace    = $secretparts[1]
                    secretname   = $secretparts[2]
                    secretkey    = $secretparts[3]
                    secretvalues = @($secretvalue)
                }
            }
        }
    }

    Write-Verbose 'GetListOfSecretsInVault: Done'
    return $Return

}

Export-ModuleMember -Function 'GetListOfSecretsInVault'