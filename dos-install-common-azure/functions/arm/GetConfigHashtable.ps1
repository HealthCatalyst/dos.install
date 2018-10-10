<#
  .SYNOPSIS
  GetConfigHashtable
  
  .DESCRIPTION
  GetConfigHashtable
  
  .INPUTS
  GetConfigHashtable - The name of GetConfigHashtable

  .OUTPUTS
  None
  
  .EXAMPLE
  GetConfigHashtable

  .EXAMPLE
  GetConfigHashtable


#>
function GetConfigHashtable() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)] 
        [PSObject] 
        $clientConfigObject
    )

    Write-Verbose 'GetConfigHashtable: Starting'
    $config = @{}
    $config.Add("kubernetesVersion", $clientConfigObject.kubernetes.version)
    $config.Add("privateClusterEnabled", $clientConfigObject.kubernetes.privateCluster.enabled)

    # we need to only add jumpbox config if it's wanted.  So maybe we create two K8s configs.  One with a jumpbox, one without?
    if ($clientConfigObject.kubernetes.privateCluster.jumpboxProfile) {
        $config.Add("jumpboxName", $clientConfigObject.kubernetes.privateCluster.jumpboxProfile.name)
        $config.Add("jumpboxVmSize", $clientConfigObject.kubernetes.privateCluster.jumpboxProfile.vmSize)
        $config.Add("jumpboxDiskSizeGB", $clientConfigObject.kubernetes.privateCluster.jumpboxProfile.osDiskSizeGB)
        $config.Add("jumpboxUsername", $clientConfigObject.kubernetes.privateCluster.jumpboxProfile.username)
  
        # we need to be smart here and pull from keyvault if public key is not defined
        $jbPublicKey = ""
        if ([string]::IsNullOrEmpty($clientConfigObject.kubernetes.privateCluster.jumpboxProfile.publicKey)) {
            $jbPublicKey = GetKeyVaultSecretValue -keyVaultName $clientConfigObject.kubernetes.privateCluster.jumpboxProfile.keyVault.vaultName `
                -keyVaultSecretName $clientConfigObject.kubernetes.privateCluster.jumpboxProfile.keyVault.secretName
        }
        else {
            $jbPublicKey = $clientConfigObject.kubernetes.privateCluster.jumpboxProfile.publicKey
        }
        $config.Add("jumpboxPublicKey", $jbPublicKey)
    }

    $config.Add("masterVmSize", $clientConfigObject.kubernetes.masterProfile.vmSize)

    $subnetId = BuildSubnetId -subscriptionId $clientConfigObject.subscriptionId `
        -resourceGroup $clientConfigObject.vnet.resourceGroup `
        -vnetName $clientConfigObject.vnet.name `
        -subnetName $clientConfigObject.acs.subnetName

    $config.Add("vnetSubnetId", $subnetId)
    $config.Add("firstConsecutiveStaticIP", $clientConfigObject.acs.firstConsecutiveStaticIP)
    $config.Add("vnetCidr", $clientConfigObject.acs.vnetCidr)
    $config.Add("agentName", $clientConfigObject.kubernetes.agentProfile.agentName)
    $config.Add("agentVmSize", $clientConfigObject.kubernetes.agentProfile.vmSize)
    $config.Add("username", $clientConfigObject.security.username)

    $profilePublicKey = ""
    if ([string]::IsNullOrEmpty($clientConfigObject.security.publicKey)) {
        $profilePublicKey = GetKeyVaultSecretValue -keyVaultName $clientConfigObject.security.keyVault.vaultName `
            -keyVaultSecretName $clientConfigObject.security.keyVault.secretName
    }
    else {
        $profilePublicKey = $clientConfigObject.security.publicKey
    }
    $config.Add("publicKey", $profilePublicKey)

    $config.Add("servicePrincipalClientId", $clientConfigObject.servicePrincipalProfile.clientId)
    $config.Add("servicePrincipalSecret", $clientConfigObject.servicePrincipalProfile.secret)


    Write-Verbose 'GetConfigHashtable: Done'
    return $config
}

Export-ModuleMember -Function "GetConfigHashtable"