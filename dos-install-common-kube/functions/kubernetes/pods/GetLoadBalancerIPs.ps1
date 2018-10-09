<#
  .SYNOPSIS
  GetLoadBalancerIPs
  
  .DESCRIPTION
  GetLoadBalancerIPs
  
  .INPUTS
  GetLoadBalancerIPs - The name of GetLoadBalancerIPs

  .OUTPUTS
  None
  
  .EXAMPLE
  GetLoadBalancerIPs

  .EXAMPLE
  GetLoadBalancerIPs


#>
function GetLoadBalancerIPs() {
    [CmdletBinding()]
    param
    (
    )

    Write-Verbose 'GetLoadBalancerIPs: Starting'
    [hashtable]$Return = @{} 

    $startDate = Get-Date
    $timeoutInMinutes = 10
    $loadbalancer = "traefik-ingress-service-public"
    $loadbalancerInternal = "traefik-ingress-service-internal" 

    [int] $counter = 0
    Write-Information -MessageData "Waiting for IP to get assigned to the load balancer (Note: It can take upto 5 minutes for Azure to finish creating the load balancer)"
    Do { 
        $counter = $counter + 1
        $externalIP = $(kubectl get svc $loadbalancer -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}')
        if (!$externalIP) {
            Write-Information -MessageData "$counter"
            Start-Sleep -Seconds 10
        }
    }
    while ([string]::IsNullOrWhiteSpace($externalIP) -and ($startDate.AddMinutes($timeoutInMinutes) -gt (Get-Date)))
    Write-Information -MessageData "External IP: $externalIP"
    
    $counter = 0
    Write-Information -MessageData "Waiting for IP to get assigned to the internal load balancer (Note: It can take upto 5 minutes for Azure to finish creating the load balancer)"
    Do { 
        $counter = $counter + 1
        $internalIP = $(kubectl get svc $loadbalancerInternal -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}')
        if (!$internalIP) {
            Write-Information -MessageData "$counter"
            Start-Sleep -Seconds 10
        }
    }
    while ([string]::IsNullOrWhiteSpace($internalIP) -and ($startDate.AddMinutes($timeoutInMinutes) -gt (Get-Date)))
    Write-Information -MessageData "Internal IP: $internalIP"

    $Return.ExternalIP = $externalIP
    $Return.InternalIP = $internalIP
    

    Write-Verbose 'GetLoadBalancerIPs: Done'
    return $Return

}

Export-ModuleMember -Function "GetLoadBalancerIPs"