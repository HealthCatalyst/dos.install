<#
.SYNOPSIS
InstallProductInAzure

.DESCRIPTION
InstallProductInAzure

.INPUTS
InstallProductInAzure - The name of InstallProductInAzure

.OUTPUTS
None

.EXAMPLE
InstallProductInAzure

.EXAMPLE
InstallProductInAzure


#>
function InstallProductInAzure() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $namespace
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $packageUrl
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $local
    )

    Write-Verbose 'InstallProductInAzure: Starting'

    Write-Host "Installing product from $packageUrl into $namespace"

    $loadbalancerInfo = $(GetLoadBalancerIPs)
    [string] $externalIP = $loadbalancerInfo.ExternalIP
    [string] $internalIP = $loadbalancerInfo.InternalIP

    [string] $internalSubnetName = $(kubectl get svc -l "k8s-app-internal=traefik-ingress-lb" -n kube-system -o jsonpath="{.metadata.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-internal-subnet}")
    [string] $externalSubnetName = $(kubectl get svc -l "k8s-app-external=traefik-ingress-lb" -n kube-system -o jsonpath="{.metadata.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-internal-subnet}")

    if (!$externalSubnetName) {$externalSubnetName = $internalSubnetName}
    if (!$internalSubnetName) {$internalSubnetName = $externalSubnetName}

    InstallStackInAzure `
        -namespace $namespace `
        -package $namespace `
        -packageUrl $packageUrl `
        -Ssl $false `
        -ExternalIP $externalIP `
        -InternalIP $internalIP `
        -ExternalSubnet $externalSubnetName `
        -InternalSubnet $internalSubnetName `
        -IngressInternalType "public" `
        -IngressExternalType "public" `
        -local $local `
        -isAzure $true `
        -Verbose

    Write-Verbose 'InstallProductInAzure: Done'

}

Export-ModuleMember -Function 'InstallProductInAzure'