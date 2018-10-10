<#
  .SYNOPSIS
  GetKeyVaultSecretValue
  
  .DESCRIPTION
  GetKeyVaultSecretValue
  
  .INPUTS
  GetKeyVaultSecretValue - The name of GetKeyVaultSecretValue

  .OUTPUTS
  None
  
  .EXAMPLE
  GetKeyVaultSecretValue

  .EXAMPLE
  GetKeyVaultSecretValue


#>
function GetKeyVaultSecretValue()
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true)]
    [string] 
    $keyVaultName
    ,
    [Parameter(Mandatory = $true)] 
    [string] 
    $keyVaultSecretName
  )

  Write-Verbose 'GetKeyVaultSecretValue: Starting'

  $secret = Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name $keyVaultSecretName
  return $secret.SecretValueText #.Replace('"', '\"')
  
  Write-Verbose 'GetKeyVaultSecretValue: Done'

}

Export-ModuleMember -Function "GetKeyVaultSecretValue"