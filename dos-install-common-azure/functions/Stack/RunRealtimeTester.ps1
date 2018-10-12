<#
.SYNOPSIS
RunRealtimeTester

.DESCRIPTION
RunRealtimeTester

.INPUTS
RunRealtimeTester - The name of RunRealtimeTester

.OUTPUTS
None

.EXAMPLE
RunRealtimeTester

.EXAMPLE
RunRealtimeTester


#>
function RunRealtimeTester() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $baseUrl
    )

    Write-Verbose 'RunRealtimeTester: Starting'
    # show commands to download the tester and run it passing in certhostname and password
    $certhostname = $(ReadSecretValue certhostname $namespace)
    $certpassword = $(ReadSecretPassword certpassword $namespace)

    Write-Host "Run on your client machine in a PowerShell window:"
    Write-Host "curl -useb $baseUrl/realtime/realtimetester.ps1 | iex $certhostname $certpassword"
    Write-Verbose 'RunRealtimeTester: Done'

}

Export-ModuleMember -Function 'RunRealtimeTester'