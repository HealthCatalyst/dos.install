<#
.SYNOPSIS
TestAzureLoadBalancer

.DESCRIPTION
TestAzureLoadBalancer

.INPUTS
TestAzureLoadBalancer - The name of TestAzureLoadBalancer

.OUTPUTS
None

.EXAMPLE
TestAzureLoadBalancer

.EXAMPLE
TestAzureLoadBalancer


#>
function TestAzureLoadBalancer()
{
    [CmdletBinding()]
    param
    (
    )

    Write-Verbose 'TestAzureLoadBalancer: Starting'
    $AKS_PERS_RESOURCE_GROUP = ReadSecretData -secretname azure-secret -valueName resourcegroup

    $urlAndIPForLoadBalancer = $(GetUrlAndIPForLoadBalancer "$AKS_PERS_RESOURCE_GROUP")
    $url = $($urlAndIPForLoadBalancer.Url)
    $ip = $($urlAndIPForLoadBalancer.IP)

    # Invoke-WebRequest -useb -Headers @{"Host" = "nlp.$customerid.healthcatalyst.net"} -Uri http://$loadBalancerIP/nlpweb | Select-Object -Expand Content

    Write-Host "To test out the load balancer, open Git Bash and run:"
    Write-Host "curl --header 'Host: $url' 'http://$ip/external' -k"

    Write-Verbose 'TestAzureLoadBalancer: Done'

}

Export-ModuleMember -Function 'TestAzureLoadBalancer'