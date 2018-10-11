<#
  .SYNOPSIS
  AssertStringIsNotNull
  
  .DESCRIPTION
  AssertStringIsNotNull
  
  .INPUTS
  AssertStringIsNotNull - The name of AssertStringIsNotNull

  .OUTPUTS
  None
  
  .EXAMPLE
  AssertStringIsNotNull

  .EXAMPLE
  AssertStringIsNotNull


#>
function AssertStringIsNotNull()
{
  [CmdletBinding()]
  param
  (
    [parameter (Mandatory = $false) ]
    [ValidateNotNull()]
    [string] 
    $text
  )
}

function AssertStringIsNotNullOrEmpty()
{
  [CmdletBinding()]
  param
  (
    [parameter (Mandatory = $false) ]
    [ValidateNotNullOrEmpty()]
    [string] 
    $text
  )
}

Export-ModuleMember -Function "AssertStringIsNotNull"
Export-ModuleMember -Function "AssertStringIsNotNullOrEmpty"