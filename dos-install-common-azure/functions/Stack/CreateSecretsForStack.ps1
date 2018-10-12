<#
.SYNOPSIS
CreateSecretsForStack

.DESCRIPTION
CreateSecretsForStack

.INPUTS
CreateSecretsForStack - The name of CreateSecretsForStack

.OUTPUTS
None

.EXAMPLE
CreateSecretsForStack

.EXAMPLE
CreateSecretsForStack


#>
function CreateSecretsForStack() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $namespace
    )

    Write-Verbose 'CreateSecretsForStack: Starting'

    switch ( $namespace ) {
        "fabricrealtime" {
            Write-Host "$namespace"
            SaveSecretValue -secretname "certhostname" -valueName "value" -value "mycerthostname" -namespace "$namespace"
            SaveSecretPassword -secretname "mysqlrootpassword" -value "mysqlrootpassword" -namespace "$namespace"
            SaveSecretPassword -secretname "mysqlpassword" -value "mysqlpassword" -namespace "$namespace"
            SaveSecretPassword -secretname "certpassword" -value "mycertpassword" -namespace "$namespace"
            SaveSecretPassword -secretname "rabbitmqmgmtuipassword" -value "myrabbitmqmgmtuipassword" -namespace "$namespace"
        }
    }
    Write-Verbose 'CreateSecretsForStack: Done'
}

Export-ModuleMember -Function 'CreateSecretsForStack'