<#
  .SYNOPSIS
  InstallStack

  .DESCRIPTION
  InstallStack

  .INPUTS
  InstallStack - The name of InstallStack

  .OUTPUTS
  None

  .EXAMPLE
  InstallStack

  .EXAMPLE
  InstallStack


#>
function InstallStackInAzure() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $namespace
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $package
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $packageUrl
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $Ssl
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $isAzure
        ,
        [string]
        $externalIp
        ,
        [string]
        $internalIp
        ,
        [string]
        $externalSubnetName
        ,
        [string]
        $internalSubnetName
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $IngressInternalType
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $IngressExternalType
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [bool]
        $local
    )

    Write-Verbose 'InstallStackInAzure: Starting'

    [hashtable]$Return = @{}

    if ($namespace -ne "kube-system") {
        if ($isAzure) {
            CreateAzureStorage -namespace $namespace
        }
        else {
            CreateOnPremStorage -namespace $namespace
        }
    }

    CreateSecretsForStack -namespace $namespace

    InstallStackInKubernetes `
        -namespace $namespace `
        -package $package `
        -packageUrl $packageUrl `
        -Ssl $Ssl `
        -externalIp $externalIp `
        -internalIp $internalIp `
        -ExternalSubnet $externalSubnetName `
        -InternalSubnet $internalSubnetName `
        -IngressExternalType $IngressExternalType `
        -IngressInternalType $IngressInternalType

    # if ($isAzure) {
    #     WaitForLoadBalancers -resourceGroup $(GetResourceGroup).ResourceGroup
    # }

    # open ports specified
    # if ($(HasProperty -object $($config) "ports")) {
    #     Write-Information -MessageData "Opening ports"
    #     if ($isAzure) {
    #         $resourceGroup = $(GetResourceGroup).ResourceGroup
    #         foreach ($portEntry in $config.ports) {
    #             OpenPortInAzure -resourceGroup $resourceGroup -port $portEntry.port -name $portEntry.name -protocol $portEntry.protocol -type $portEntry.type
    #         }
    #     }
    #     else {
    #         foreach ($portEntry in $config.ports) {
    #             OpenPortOnPrem -port $portEntry.port -name $portEntry.name -protocol $portEntry.protocol -type $portEntry.type
    #         }
    #     }
    # }

    # if ($isAzure) {
    #     $resourceGroup = $(GetResourceGroup).ResourceGroup
    #     WaitForLoadBalancersToGetIPs -namespace $namespace
    #     # MovePortsToLoadBalancerForNamespace -resourceGroup $resourceGroup -namespace $namespace
    # }

    Write-Verbose 'InstallStackInAzure: Done'
    return $Return
}

Export-ModuleMember -Function "InstallStackInAzure"