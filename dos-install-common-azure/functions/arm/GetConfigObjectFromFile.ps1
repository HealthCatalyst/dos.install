<#
  .SYNOPSIS
  GetConfigObjectFromFile
  
  .DESCRIPTION
  GetConfigObjectFromFile
  
  .INPUTS
  GetConfigObjectFromFile - The name of GetConfigObjectFromFile

  .OUTPUTS
  None
  
  .EXAMPLE
  GetConfigObjectFromFile

  .EXAMPLE
  GetConfigObjectFromFile


#>
function GetConfigObjectFromFile()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string] 
    $configFilePath
  )

  Write-Verbose 'GetConfigObjectFromFile: Starting'

  $configFileContent = StripJsonComments -fileContent (Get-Content $configFilePath -Raw)
  $configObject = $configFileContent | ConvertFrom-Json
  $configObject
  
  Write-Verbose 'GetConfigObjectFromFile: Done'

}

Export-ModuleMember -Function "GetConfigObjectFromFile"