<#
  .SYNOPSIS
  InstallLoadBalancerHelmPackage
  
  .DESCRIPTION
  InstallLoadBalancerHelmPackage
  
  .INPUTS
  InstallLoadBalancerHelmPackage - The name of InstallLoadBalancerHelmPackage

  .OUTPUTS
  None
  
  .EXAMPLE
  InstallLoadBalancerHelmPackage

  .EXAMPLE
  InstallLoadBalancerHelmPackage


#>
function InstallLoadBalancerHelmPackage() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ExternalIP
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $InternalIP
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $ExternalSubnet
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $InternalSubnet
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $IngressInternalType
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $IngressExternalType
    )

    Write-Verbose 'InstallLoadBalancerHelmPackage: Starting'

    $package = "fabricloadbalancer"

    Write-Output "Removing old deployment"
    helm del --purge $package

    Write-Output "Install helm package"
    helm install ./fabricloadbalancer `
        --name $package `
        --namespace kube-system `
        --set ExternalIP="$ExternalIP" `
        --set InternalIP="$InternalIP" `
        --set ExternalSubnet="$ExternalSubnet" `
        --set InternalSubnet="$InternalSubnet" `
        --set ingressInternalType="$IngressInternalType" `
        --set ingressExternalType="$IngressExternalType" `
        --debug

    Write-Host "Listing packages"
    helm list 

    Write-Verbose 'InstallLoadBalancerHelmPackage: Done'

}

Export-ModuleMember -Function "InstallLoadBalancerHelmPackage"