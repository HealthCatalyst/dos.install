<#
  .SYNOPSIS
  StripJsonComments
  
  .DESCRIPTION
  StripJsonComments
  
  .INPUTS
  StripJsonComments - The name of StripJsonComments

  .OUTPUTS
  None
  
  .EXAMPLE
  StripJsonComments

  .EXAMPLE
  StripJsonComments


#>
function StripJsonComments()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)] 
    [string] 
    $fileContent
  )

  Write-Verbose 'StripJsonComments: Starting'

  $content = $fileContent -replace "[^:]\/\/.*?\n", ""
  $content 
  
  Write-Verbose 'StripJsonComments: Done'

}

Export-ModuleMember -Function "StripJsonComments"