<#
  .SYNOPSIS
  SetupNetworkSecurity
  
  .DESCRIPTION
  SetupNetworkSecurity
  
  .INPUTS
  SetupNetworkSecurity - The name of SetupNetworkSecurity

  .OUTPUTS
  None
  
  .EXAMPLE
  SetupNetworkSecurity

  .EXAMPLE
  SetupNetworkSecurity


#>
function SetupNetworkSecurity()
{
  [CmdletBinding()]
  param
  (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        $config
  )

  Write-Verbose 'SetupNetworkSecurity: Starting'

  $AKS_IP_WHITELIST = ""

  $AKS_PERS_RESOURCE_GROUP = $config.azure.resourceGroup
  $AKS_PERS_LOCATION = $config.azure.location

  # Get location name from resource group
  $AKS_PERS_LOCATION = (Get-AzureRmResourceGroup -Name "$AKS_PERS_RESOURCE_GROUP").Location
  Write-Host "Using location: [$AKS_PERS_LOCATION]"

  $customerid = $config.customerid

  if ([string]::IsNullOrWhiteSpace($customerid)) {
      # https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/
      throw "customerid is null in config"
  }

  $customerid = $customerid.ToLower().Trim()
  Write-Host "Customer ID: $customerid"

  $ingressExternalType = $config.ingress.external.type
  $ingressInternalType = $config.ingress.internal.type

  if ([string]::IsNullOrWhiteSpace($ingressExternalType)) {
      # https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/
      throw "ingress.external.type is null in config"
  }
  if ([string]::IsNullOrWhiteSpace($ingressInternalType)) {
      throw "ingress.internal.type is null in config"
  }
  if ([string]::IsNullOrWhiteSpace($($config.dns.name))) {
      throw "dns.name is null in config"
  }

  $AKS_IP_WHITELIST = $config.ingress.external.whitelist

  # read the vnet and subnet info from kubernetes secret
  $AKS_VNET_NAME = $config.networking.vnet
  $AKS_SUBNET_NAME = $config.networking.subnet
  $AKS_SUBNET_RESOURCE_GROUP = $config.networking.subnet_resource_group

  Write-Host "Setting up Network Security Group for the subnet"

  # setup network security group
  $AKS_PERS_NETWORK_SECURITY_GROUP = "$($AKS_PERS_RESOURCE_GROUP.ToLower())-nsg"

  $existingNetworkSecurityGroup = $((Get-AzureRmNetworkSecurityGroup -Name $AKS_PERS_NETWORK_SECURITY_GROUP -ResourceGroupName "$AKS_PERS_RESOURCE_GROUP" -ErrorAction SilentlyContinue).Name)
  if ([string]::IsNullOrWhiteSpace($existingNetworkSecurityGroup)) {

      Write-Host "Creating the Network Security Group for the subnet"
      New-AzureRmNetworkSecurityGroup -Name $AKS_PERS_NETWORK_SECURITY_GROUP -ResourceGroupName $AKS_PERS_RESOURCE_GROUP -Location $AKS_PERS_LOCATION
  }
  else {
      Write-Host "Network Security Group already exists: $AKS_PERS_NETWORK_SECURITY_GROUP"
  }

  if ($($config.network_security_group.create_nsg_rules)) {
      Write-Host "Adding or updating rules to Network Security Group for the subnet"
      $sourceTagForAdminAccess = "VirtualNetwork"
      if ($($config.allow_kubectl_from_outside_vnet)) {
          $sourceTagForAdminAccess = "Internet"
          Write-Host "Enabling admin access to cluster from Internet"
      }

      $sourceTagForHttpAccess = "Internet"
      if (![string]::IsNullOrWhiteSpace($AKS_IP_WHITELIST)) {
          $sourceTagForHttpAccess = $AKS_IP_WHITELIST
      }

      DeleteNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP -rulename "HttpPort"
      DeleteNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP -rulename "HttpsPort"

      SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
          -rulename "allow_kube_tls" `
          -ruledescription "allow kubectl and HTTPS access from ${sourceTagForAdminAccess}." `
          -sourceTag "${sourceTagForAdminAccess}" -port 443 -priority 100 

      SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
          -rulename "allow_http" `
          -ruledescription "allow HTTP access from ${sourceTagForAdminAccess}." `
          -sourceTag "${sourceTagForAdminAccess}" -port 80 -priority 101
        
      SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
          -rulename "allow_ssh" `
          -ruledescription "allow SSH access from ${sourceTagForAdminAccess}." `
          -sourceTag "${sourceTagForAdminAccess}" -port 22 -priority 104

      SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
          -rulename "allow_mysql" `
          -ruledescription "allow MySQL access from ${sourceTagForAdminAccess}." `
          -sourceTag "${sourceTagForAdminAccess}" -port 3306 -priority 205
        
      # if we already have opened the ports for admin access then we're not allowed to add another rule for opening them
      if (($sourceTagForHttpAccess -eq "Internet") -and ($sourceTagForAdminAccess -eq "Internet")) {
          Write-Host "Since we already have rules open port 80 and 443 to the Internet, we do not need to create separate ones for the Internet"
      }
      else {
          if ($($config.ingress.external) -ne "vnetonly") {
              SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
                  -rulename "HttpPort" `
                  -ruledescription "allow HTTP access from ${sourceTagForHttpAccess}." `
                  -sourceTag "${sourceTagForHttpAccess}" -port 80 -priority 500

              SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
                  -rulename "HttpsPort" `
                  -ruledescription "allow HTTPS access from ${sourceTagForHttpAccess}." `
                  -sourceTag "${sourceTagForHttpAccess}" -port 443 -priority 501
          }
      }

      $nsgid = az network nsg list --resource-group ${AKS_PERS_RESOURCE_GROUP} --query "[?name == '${AKS_PERS_NETWORK_SECURITY_GROUP}'].id" -o tsv
      Write-Host "Found ID for ${AKS_PERS_NETWORK_SECURITY_GROUP}: $nsgid"

      Write-Host "Setting NSG into subnet"
      az network vnet subnet update -n "${AKS_SUBNET_NAME}" -g "${AKS_SUBNET_RESOURCE_GROUP}" --vnet-name "${AKS_VNET_NAME}" --network-security-group "$nsgid" --query "provisioningState" -o tsv
  }

  $externalIp = ""
  if ($($config.ingress.external.ipAddress)) {
      $externalIp = $($config.ingress.external.ipAddress);
  }
  elseif ("$($config.ingress.external.type)" -ne "vnetonly") {
      Write-Host "Setting up a public load balancer"

      $ipResourceGroup = $AKS_PERS_RESOURCE_GROUP
      $publicIpName = "IngressPublicIP"
      $externalip = Get-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup
      if ([string]::IsNullOrWhiteSpace($externalip)) {
          New-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup -AllocationMethod Static -Location $AKS_PERS_LOCATION
          $externalip = Get-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup
      }  
      Write-Host "Using Public IP: [$externalip]"
  }

  Write-Verbose 'SetupNetworkSecurity: Done'

}

Export-ModuleMember -Function "SetupNetworkSecurity"