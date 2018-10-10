<#
  .SYNOPSIS
  BuildSubnetId
  
  .DESCRIPTION
  BuildSubnetId
  
  .INPUTS
  BuildSubnetId - The name of BuildSubnetId

  .OUTPUTS
  None
  
  .EXAMPLE
  BuildSubnetId

  .EXAMPLE
  BuildSubnetId


#>
function BuildSubnetId()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)] [string] $subscriptionId,
    [Parameter(Mandatory = $true)] [string] $resourceGroup,
    [Parameter(Mandatory = $true)] [string] $vnetName,
    [Parameter(Mandatory = $true)] [string] $subnetName
  )

  Write-Verbose 'BuildSubnetId: Starting'

  $Return = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnetName"

  Write-Verbose 'BuildSubnetId: Done'

  return $Return
}

Export-ModuleMember -Function "BuildSubnetId"