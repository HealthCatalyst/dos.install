<#
  .SYNOPSIS
  AssignPermissionsToServicePrincipal
  
  .DESCRIPTION
  AssignPermissionsToServicePrincipal
  
  .INPUTS
  AssignPermissionsToServicePrincipal - The name of AssignPermissionsToServicePrincipal

  .OUTPUTS
  None
  
  .EXAMPLE
  AssignPermissionsToServicePrincipal

  .EXAMPLE
  AssignPermissionsToServicePrincipal


#>
function AssignPermissionsToServicePrincipal()
{
  [CmdletBinding()]
  param
  (
      [Parameter(Mandatory=$true)]
      [string]
      $applicationId
      ,
      [Parameter(Mandatory=$true)]
      [string]
      $objectId      
  )

  Write-Verbose 'AssignPermissionsToServicePrincipal: Starting'

  New-AzureRmRoleAssignment -RoleDefinitionName "Contributor" -ApplicationId $applicationId

  Write-Verbose 'AssignPermissionsToServicePrincipal: Done'

}

Export-ModuleMember -Function "AssignPermissionsToServicePrincipal"