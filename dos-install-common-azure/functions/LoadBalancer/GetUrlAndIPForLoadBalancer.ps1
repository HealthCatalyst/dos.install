<#
.SYNOPSIS
GetUrlAndIPForLoadBalancer

.DESCRIPTION
GetUrlAndIPForLoadBalancer

.INPUTS
GetUrlAndIPForLoadBalancer - The name of GetUrlAndIPForLoadBalancer

.OUTPUTS
None

.EXAMPLE
GetUrlAndIPForLoadBalancer

.EXAMPLE
GetUrlAndIPForLoadBalancer


#>
function GetUrlAndIPForLoadBalancer() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'GetUrlAndIPForLoadBalancer: Starting'
    [hashtable]$Return = @{}

    LoginToAzure

    $subscriptionInfo = $(GetCurrentAzureSubscription)

    $IS_CAFE_ENVIRONMENT = $subscriptionInfo.IS_CAFE_ENVIRONMENT

    $loadBalancerInfo = $(GetLoadBalancerIPs)
    $loadBalancerIP = $loadBalancerInfo.ExternalIP
    $loadBalancerInternalIP = $loadBalancerInfo.InternalIP

    if ([string]::IsNullOrWhiteSpace($loadBalancerIP)) {
        $loadBalancerIP = $loadBalancerInternalIP
    }

    if ($IS_CAFE_ENVIRONMENT) {
        $customerid = ReadSecretValue -secretname customerid
        $customerid = $customerid.ToLower().Trim()
        $url = "dashboard.$customerid.healthcatalyst.net"
        $loadBalancerIP = $loadBalancerInternalIP
    }
    else {
        $url = $(GetPublicNameofMasterVM( $resourceGroup)).Name
    }

    $Return.IP = $loadBalancerIP
    $Return.Url = $url

    Write-Verbose 'GetUrlAndIPForLoadBalancer: Done'
    return $Return

}

Export-ModuleMember -Function 'GetUrlAndIPForLoadBalancer'