<#
  .SYNOPSIS
  LoginToAzure
  
  .DESCRIPTION
  LoginToAzure
  
  .INPUTS
  LoginToAzure - The name of LoginToAzure

  .OUTPUTS
  None
  
  .EXAMPLE
  LoginToAzure

  .EXAMPLE
  LoginToAzure


#>
function LoginToAzure()
{
  [CmdletBinding()]
  param
  (
  )

  Write-Verbose 'LoginToAzure: Starting'

  [bool] $needLogin = $true
  Try 
  {
      $content = Get-AzureRmContext
      if ($content) 
      {
          $needLogin = ([string]::IsNullOrEmpty($content.Account))
      } 
  } 
  Catch 
  {
      if ($_ -like "*Login-AzureRmAccount to login*") 
      {
          $needLogin = $true
      } 
      else 
      {
          throw
      }
  }

  if ($needLogin)
  {
      Login-AzureRmAccount
  }

  Write-Verbose 'LoginToAzure: Done'

}

Export-ModuleMember -Function "LoginToAzure"