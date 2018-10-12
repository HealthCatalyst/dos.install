<#
.SYNOPSIS
MovePortsToLoadBalancer

.DESCRIPTION
MovePortsToLoadBalancer

.INPUTS
MovePortsToLoadBalancer - The name of MovePortsToLoadBalancer

.OUTPUTS
None

.EXAMPLE
MovePortsToLoadBalancer

.EXAMPLE
MovePortsToLoadBalancer


#>
function MovePortsToLoadBalancer() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'MovePortsToLoadBalancer: Starting'
    [hashtable]$Return = @{}

    $namespaces = $(kubectl get namespaces -o jsonpath="{.items[*].metadata.name}").Split(" ")

    foreach ($namespace in $namespaces) {
        MovePortsToLoadBalancerForNamespace -resourceGroup $resourceGroup -namespace $namespace
    }

    Write-Verbose 'MovePortsToLoadBalancer: Done'
    return $Return

}

Export-ModuleMember -Function 'MovePortsToLoadBalancer'