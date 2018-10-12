<#
.SYNOPSIS
ShowLoadBalancerLogs

.DESCRIPTION
ShowLoadBalancerLogs

.INPUTS
ShowLoadBalancerLogs - The name of ShowLoadBalancerLogs

.OUTPUTS
None

.EXAMPLE
ShowLoadBalancerLogs

.EXAMPLE
ShowLoadBalancerLogs


#>
function ShowLoadBalancerLogs() {
    [CmdletBinding()]
    param
    (
    )

    Write-Verbose 'ShowLoadBalancerLogs: Starting'
    # kubectl logs --namespace=kube-system -l k8s-app=traefik-ingress-lb-onprem --tail=100
    $pods = $(kubectl get pods -l k8s-traefik=traefik -n kube-system -o jsonpath='{.items[*].metadata.name}')
    foreach ($pod in $pods.Split(" ")) {
        Write-Host "=============== Pod: $pod ================="
        kubectl logs --tail=20 $pod -n kube-system
    }
    Write-Verbose 'ShowLoadBalancerLogs: Done'

}

Export-ModuleMember -Function 'ShowLoadBalancerLogs'