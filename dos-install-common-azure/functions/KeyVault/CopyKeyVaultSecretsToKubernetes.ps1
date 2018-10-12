<#
.SYNOPSIS
CopyKeyVaultSecretsToKubernetes

.DESCRIPTION
CopyKeyVaultSecretsToKubernetes

.INPUTS
CopyKeyVaultSecretsToKubernetes - The name of CopyKeyVaultSecretsToKubernetes

.OUTPUTS
None

.EXAMPLE
CopyKeyVaultSecretsToKubernetes

.EXAMPLE
CopyKeyVaultSecretsToKubernetes


#>
function CopyKeyVaultSecretsToKubernetes() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'CopyKeyVaultSecretsToKubernetes: Starting'

    [hashtable]$Return = @{}
    Write-Verbose "Copying existing secrets from keyvault to kubernetes"

    $secrets = $(GetListOfSecretsInVault -resourceGroup $resourceGroup).Secrets

    foreach ($secret in $secrets) {
        [string] $secretname = $secret.secretname
        [string] $namespace = $secret.namespace
        $secretvalues = $secret.secretvalues
        [string] $command = "kubectl create secret generic $secretname --namespace=$namespace"
        foreach ($secretvalue in $secretvalues) {
            $command = "$command --from-literal=$($secretvalue.secretkey)=$($secretvalue.secretvalue)"
        }
        CreateNamespaceIfNotExists -namespace $namespace

        if ([string]::IsNullOrWhiteSpace($(kubectl get secret $secretname -n $namespace -o jsonpath='{.data}' --ignore-not-found=true))) {
            Invoke-Expression -Command $command
            Write-Verbose $command
        }
        else {
            Write-Verbose "secret $secretname already set in namespace $namespace so nothing to do"
        }
    }

    Write-Verbose 'CopyKeyVaultSecretsToKubernetes: Done'
    Return $Return
}

Export-ModuleMember -Function 'CopyKeyVaultSecretsToKubernetes'