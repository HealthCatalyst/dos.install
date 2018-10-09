<#
  .SYNOPSIS
  ReadSecretValue
  
  .DESCRIPTION
  ReadSecretValue
  
  .INPUTS
  ReadSecretValue - The name of ReadSecretValue

  .OUTPUTS
  None
  
  .EXAMPLE
  ReadSecretValue

  .EXAMPLE
  ReadSecretValue


#>
function ReadSecretValue() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $secretname
        , 
        [string]
        $namespace
    )

    Write-Verbose 'ReadSecretValue: Starting'
    $return = ReadSecretData -secretname $secretname -valueName "value" -namespace $namespace
    Write-Verbose 'ReadSecretValue: Done'

    Return $return
}

Export-ModuleMember -Function "ReadSecretValue"