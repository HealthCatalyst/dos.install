<#
.SYNOPSIS
CopyKubernetesSecretsToKeyVault

.DESCRIPTION
CopyKubernetesSecretsToKeyVault

.INPUTS
CopyKubernetesSecretsToKeyVault - The name of CopyKubernetesSecretsToKeyVault

.OUTPUTS
None

.EXAMPLE
CopyKubernetesSecretsToKeyVault

.EXAMPLE
CopyKubernetesSecretsToKeyVault


#>
function CopyKubernetesSecretsToKeyVault() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'CopyKubernetesSecretsToKeyVault: Starting'

    [hashtable]$Return = @{}

    Write-Information -MessageData "Copying existing kubernetes secrets to KeyVault"

    CreateKeyVault -resourceGroup $resourceGroup

    [string[]] $systemnamespaces = @("kube-system", "kube-public")

    [string[]] $namespaces = $(kubectl get namespaces -o jsonpath="{.items[*].metadata.name}").Split(" ")

    foreach ($namespace in $namespaces) {
        if ($systemnamespaces -notcontains $namespace) {
            $secrets = $(ReadAllSecretsAsHashTable -namespace $namespace)
            Write-Verbose "---- $namespace ---"
            foreach ($secret in $secrets.Secrets) {
                # echo "$($secret.secretname) in $($secret.namespace)"
                [string] $fullkey = "kubernetes00$($secret.namespace)00$($secret.secretname)"
                $secretvalues = @()
                foreach ($item in $secret.secretvalues) {
                    $secretvalues += @{
                        secretkey   = "$($item.key)"
                        secretvalue = "$($item.value)"
                    }
                }
                $secretjson = $secretvalues | ConvertTo-Json -Compress
                $secretjson = $secretjson -replace '"', "'" # az keyvault strips double quotes
                # Write-Information -MessageData "$fullkey"
                SaveKeyInVault -resourceGroup $resourceGroup -key $fullkey -value $secretjson
            }
        }
    }

    Return $Return

    Write-Verbose 'CopyKubernetesSecretsToKeyVault: Done'
}

Export-ModuleMember -Function 'CopyKubernetesSecretsToKeyVault'