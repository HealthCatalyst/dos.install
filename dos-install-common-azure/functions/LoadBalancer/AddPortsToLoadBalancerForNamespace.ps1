<#
.SYNOPSIS
AddPortsToLoadBalancerForNamespace

.DESCRIPTION
AddPortsToLoadBalancerForNamespace

.INPUTS
AddPortsToLoadBalancerForNamespace - The name of AddPortsToLoadBalancerForNamespace

.OUTPUTS
None

.EXAMPLE
AddPortsToLoadBalancerForNamespace

.EXAMPLE
AddPortsToLoadBalancerForNamespace


#>
function AddPortsToLoadBalancerForNamespace() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $expose,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $loadbalanceripAddress
    )

    Write-Verbose 'AddPortsToLoadBalancerForNamespace: Starting'
    Write-Information -MessageData "Checking ports in namespace: $namespace"
    $servicesastext = $(kubectl get svc -n $namespace -o jsonpath="{.items[?(@.metadata.labels.expose == '$expose')].metadata.name}" --ignore-not-found=true)

    if ($servicesastext) {
        foreach ($service in $servicesastext.Split(" ")) {
            Write-Information -MessageData "Checking service $service"
            $portsastext = $(kubectl get svc $service -n $namespace -o jsonpath="{.spec.ports[0].port}")
            $nodePortsastext = $(kubectl get svc $service -n $namespace -o jsonpath="{.spec.ports[0].nodePort}")
            if ($portsastext) {
                $ports = $portsastext.Split(" ")
                $nodePorts = $nodePortsastext.Split(" ")
                $nodePort = $nodePorts[0]

                foreach ($port in $ports) {
                    AddPortToLoadBalancer -loadbalanceripAddress $loadbalanceripAddress -frontendport $port -backendport $nodePort
                }
            }
        }
    }
    Write-Verbose 'AddPortsToLoadBalancerForNamespace: Done'

}

Export-ModuleMember -Function 'AddPortsToLoadBalancerForNamespace'