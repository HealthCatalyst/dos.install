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

  $whiteListIp = ""

  [string] $resourceGroup = $config.azure.resourceGroup
  AssertStringIsNotNullOrEmpty $resourceGroup

  [string] $location = (Get-AzureRmResourceGroup -Name "$resourceGroup").Location
  Write-Host "Using location: [$location]"

  [string] $customerid = $config.customerid
  AssertStringIsNotNullOrEmpty $customerid

  if ([string]::IsNullOrWhiteSpace($customerid)) {
      # https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/
      throw "customerid is null in config"
  }

  $customerid = $customerid.ToLower().Trim()
  Write-Host "Customer ID: $customerid"

  [string] $ingressExternalType = $config.ingress.external.type
  [string] $ingressInternalType = $config.ingress.internal.type

  $config | Out-String

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

  [string] $whiteListIp = $config.ingress.external.whitelist

  # read the vnet and subnet info from kubernetes secret
  [string] $vnetName = $config.networking.vnet
  [string] $subnetName = $config.networking.subnet
  [string] $subnetResourceGroup = $config.networking.subnet_resource_group

  Write-Host "Setting up Network Security Group for the subnet"

  # setup network security group
  [string] $networkSecurityResourceGroup = "$($resourceGroup.ToLower())-nsg"

  [string] $existingNetworkSecurityGroup = $((Get-AzureRmNetworkSecurityGroup -Name $networkSecurityResourceGroup -ResourceGroupName "$resourceGroup" -ErrorAction SilentlyContinue).Name)
  if ([string]::IsNullOrWhiteSpace($existingNetworkSecurityGroup)) {

      Write-Host "Creating the Network Security Group for the subnet"
      New-AzureRmNetworkSecurityGroup -Name $networkSecurityResourceGroup -ResourceGroupName $resourceGroup -Location $location
  }
  else {
      Write-Host "Network Security Group already exists: $networkSecurityResourceGroup"
  }

  if ($($config.network_security_group.create_nsg_rules)) {
      Write-Host "Adding or updating rules to Network Security Group for the subnet"
      [string] $sourceTagForAdminAccess = "VirtualNetwork"
      if ($($config.allow_kubectl_from_outside_vnet)) {
          $sourceTagForAdminAccess = "Internet"
          Write-Host "Enabling admin access to cluster from Internet"
      }

      [string] $sourceTagForHttpAccess = "Internet"
      if (![string]::IsNullOrWhiteSpace($whiteListIp)) {
          $sourceTagForHttpAccess = $whiteListIp
      }

      DeleteNetworkSecurityGroupRule -resourceGroup $resourceGroup -networkSecurityGroup $networkSecurityResourceGroup -rulename "HttpPort"
      DeleteNetworkSecurityGroupRule -resourceGroup $resourceGroup -networkSecurityGroup $networkSecurityResourceGroup -rulename "HttpsPort"

      SetNetworkSecurityGroupRule -resourceGroup $resourceGroup -networkSecurityGroup $networkSecurityResourceGroup `
          -rulename "allow_kube_tls" `
          -ruledescription "allow kubectl and HTTPS access from ${sourceTagForAdminAccess}." `
          -sourceTag "${sourceTagForAdminAccess}" -port 443 -priority 100 

      SetNetworkSecurityGroupRule -resourceGroup $resourceGroup -networkSecurityGroup $networkSecurityResourceGroup `
          -rulename "allow_http" `
          -ruledescription "allow HTTP access from ${sourceTagForAdminAccess}." `
          -sourceTag "${sourceTagForAdminAccess}" -port 80 -priority 101
        
      SetNetworkSecurityGroupRule -resourceGroup $resourceGroup -networkSecurityGroup $networkSecurityResourceGroup `
          -rulename "allow_ssh" `
          -ruledescription "allow SSH access from ${sourceTagForAdminAccess}." `
          -sourceTag "${sourceTagForAdminAccess}" -port 22 -priority 104

      SetNetworkSecurityGroupRule -resourceGroup $resourceGroup -networkSecurityGroup $networkSecurityResourceGroup `
          -rulename "allow_mysql" `
          -ruledescription "allow MySQL access from ${sourceTagForAdminAccess}." `
          -sourceTag "${sourceTagForAdminAccess}" -port 3306 -priority 205
        
      # if we already have opened the ports for admin access then we're not allowed to add another rule for opening them
      if (($sourceTagForHttpAccess -eq "Internet") -and ($sourceTagForAdminAccess -eq "Internet")) {
          Write-Host "Since we already have rules open port 80 and 443 to the Internet, we do not need to create separate ones for the Internet"
      }
      else {
          if ($($config.ingress.external) -ne "vnetonly") {
              SetNetworkSecurityGroupRule -resourceGroup $resourceGroup -networkSecurityGroup $networkSecurityResourceGroup `
                  -rulename "HttpPort" `
                  -ruledescription "allow HTTP access from ${sourceTagForHttpAccess}." `
                  -sourceTag "${sourceTagForHttpAccess}" -port 80 -priority 500

              SetNetworkSecurityGroupRule -resourceGroup $resourceGroup -networkSecurityGroup $networkSecurityResourceGroup `
                  -rulename "HttpsPort" `
                  -ruledescription "allow HTTPS access from ${sourceTagForHttpAccess}." `
                  -sourceTag "${sourceTagForHttpAccess}" -port 443 -priority 501
          }
      }

      [string] $nsgid = az network nsg list --resource-group ${resourceGroup} --query "[?name == '${networkSecurityResourceGroup}'].id" -o tsv
      Write-Host "Found ID for ${networkSecurityResourceGroup}: $nsgid"

      Write-Host "Setting NSG into subnet"
      az network vnet subnet update -n "${subnetName}" -g "${subnetResourceGroup}" --vnet-name "${vnetName}" --network-security-group "$nsgid" --query "provisioningState" -o tsv
  }

  [string] $externalIp = ""
  if ($($config.ingress.external.ipAddress)) {
      $externalIp = $($config.ingress.external.ipAddress);
  }
  elseif ("$($config.ingress.external.type)" -ne "vnetonly") {
      Write-Host "Setting up a public load balancer"

      [string] $ipResourceGroup = $resourceGroup
      [string] $publicIpName = "IngressPublicIP"
      $externalip = Get-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup
      if ([string]::IsNullOrWhiteSpace($externalip)) {
          New-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup -AllocationMethod Static -Location $location
          $externalip = Get-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup
      }  
      Write-Host "Using Public IP: [$externalip]"
  }

  Write-Verbose 'SetupNetworkSecurity: Done'
}

Export-ModuleMember -Function "SetupNetworkSecurity"