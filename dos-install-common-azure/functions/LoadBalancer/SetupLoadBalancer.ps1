<#
  .SYNOPSIS
  SetupLoadBalancer
  
  .DESCRIPTION
  SetupLoadBalancer
  
  .INPUTS
  SetupLoadBalancer - The name of SetupLoadBalancer

  .OUTPUTS
  None
  
  .EXAMPLE
  SetupLoadBalancer

  .EXAMPLE
  SetupLoadBalancer


#>
function SetupLoadBalancer()
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

  Write-Verbose 'SetupLoadBalancer: Starting'

  Write-Verbose 'SetupLoadBalancer: Done'

}

Export-ModuleMember -Function "SetupLoadBalancer"