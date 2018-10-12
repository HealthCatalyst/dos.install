<#
.SYNOPSIS
MovePortsToLoadBalancerForNamespace

.DESCRIPTION
MovePortsToLoadBalancerForNamespace

.INPUTS
MovePortsToLoadBalancerForNamespace - The name of MovePortsToLoadBalancerForNamespace

.OUTPUTS
None

.EXAMPLE
MovePortsToLoadBalancerForNamespace

.EXAMPLE
MovePortsToLoadBalancerForNamespace


#>
function MovePortsToLoadBalancerForNamespace() {
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
        $namespace
    )

    Write-Verbose 'MovePortsToLoadBalancerForNamespace: Starting'
    [hashtable]$Return = @{}

    Write-Information -MessageData "Checking if load balancers are setup correctly for resourceGroup: $resourceGroup in namespace: $namespace"
    # 1. assign the nics to the loadbalancer

    # find loadbalancer with name
    $loadbalancer = "${resourceGroup}-internal"

    $loadbalancerExists = $(az network lb show --name $loadbalancer --resource-group $resourceGroup --query "name" -o tsv)

    # if internal load balancer exists then fix it
    if ([string]::IsNullOrWhiteSpace($loadbalancerExists)) {
        Write-Information -MessageData "Loadbalancer $loadbalancer does not exist so no need to fix it"
        return
    }
    else {
        Write-Information -MessageData "loadbalancer $loadbalancer exists with name: $loadbalancerExists"
    }

    $loadbalancerInfo = $(GetLoadBalancerIPs)
    $loadbalanceripAddress = $loadbalancerInfo.InternalIP

    if ($loadbalanceripAddress) {
        $expose = "internal"
        Write-Information -MessageData "Checking ports for $expose load balancer"

        AddPortsToLoadBalancerForNamespace -namespace $namespace -expose $expose -loadbalanceripAddress $loadbalanceripAddress
    }

    $loadbalanceripAddress = $loadbalancerInfo.ExternalIP
    if ($loadbalanceripAddress) {

        $expose = "external"
        Write-Information -MessageData "Checking ports for $expose load balancer"

        AddPortsToLoadBalancerForNamespace -namespace $namespace -expose $expose -loadbalanceripAddress $loadbalanceripAddress
    }

    Write-Verbose 'MovePortsToLoadBalancerForNamespace: Done'
    return $Return

}

Export-ModuleMember -Function 'MovePortsToLoadBalancerForNamespace'