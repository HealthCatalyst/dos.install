<#
  .SYNOPSIS
  GetResourceGroup

  .DESCRIPTION
  GetResourceGroup

  .INPUTS
  GetResourceGroup - The name of GetResourceGroup

  .OUTPUTS
  None

  .EXAMPLE
  GetResourceGroup

  .EXAMPLE
  GetResourceGroup


#>
function GetResourceGroup()
{
  [CmdletBinding()]
  param
  (
  )

  Write-Verbose 'GetResourceGroup: Starting'

  [hashtable]$Return = @{}
  $Return.ResourceGroup = ReadSecretData -secretname azure-secret -valueName "resourcegroup"

  Write-Verbose 'GetResourceGroup: Done'
  return $Return
}

Export-ModuleMember -Function "GetResourceGroup"