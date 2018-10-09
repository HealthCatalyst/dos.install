<#
  .SYNOPSIS
  TODO
  
  .DESCRIPTION
  TODO
  
  .INPUTS
  TODO - The name of TODO

  .OUTPUTS
  None
  
  .EXAMPLE
  TODO

  .EXAMPLE
  TODO


#>
function TODO()
{
  [CmdletBinding()]
  param
  (
    [parameter (Mandatory = $false) ]
    [string] $OutputPathFolder = 'C:\PS\Pester-course\demo\completed-final-module\Podcast-Data\'
    ,
    [parameter (Mandatory = $false) ]
    [string] $XmlFileName = 'NoAgenda.xml'
    ,
    [parameter (Mandatory = $false) ]
    [string] $HtmlFileName = 'NoAgenda.html'
  )

  Write-Verbose 'TODO: Starting'

  Write-Verbose 'TODO: Done'

}

Export-ModuleMember -Function "TODO"