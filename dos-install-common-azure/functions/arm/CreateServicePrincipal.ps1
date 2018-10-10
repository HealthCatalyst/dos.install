<#
  .SYNOPSIS
  CreateServicePrincipal
  
  .DESCRIPTION
  CreateServicePrincipal
  
  .INPUTS
  CreateServicePrincipal - The name of CreateServicePrincipal

  .OUTPUTS
  None
  
  .EXAMPLE
  CreateServicePrincipal

  .EXAMPLE
  CreateServicePrincipal


#>
function CreateServicePrincipal() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $resourceGroup
        ,
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $applicationName
    )

    $Return = @{}

    Write-Verbose 'CreateServicePrincipal: Starting'

    Add-Type -Assembly System.Web
    # $password = [System.Web.Security.Membership]::GeneratePassword(16, 3)
    $clientSecret = [guid]::NewGuid()
    $securePassword = ConvertTo-SecureString -Force -AsPlainText -String $clientSecret

    $app = $(New-AzureRmADApplication -DisplayName "$applicationName" -HomePage "http://$applicationName" -IdentifierUris "http://$applicationName" -Password $securePassword)

    $servicePrincipal = $(New-AzureRmADServicePrincipal -ApplicationId $($app.ApplicationId) -Password $securePassword)
    $servicePrincipalId = $servicePrincipal.Id

    # have to wait for service principal to finish
    do {
        $servicePrincipal = $(Get-AzureRmADServicePrincipal -ObjectId $servicePrincipalId)
        Write-Verbose "."
        Start-Sleep -Seconds 1
    } while ($null -eq $servicePrincipal)
    
    # https://github.com/Azure/azure-cli/issues/1332
    Write-Host "Sleeping to wait for Service Principal to propagate"    
    Start-Sleep -Seconds 5;

    $Return.ObjectId = $($app.ObjectId)
    $Return.ApplicationId = $($app.ApplicationId)
    $Return.ClientSecret = $clientSecret
    Write-Verbose 'CreateServicePrincipal: Done'
    return $Return
}

Export-ModuleMember -Function "CreateServicePrincipal"