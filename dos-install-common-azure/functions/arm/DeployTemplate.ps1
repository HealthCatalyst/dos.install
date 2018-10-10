<#
  .SYNOPSIS
  DeployTemplate
  
  .DESCRIPTION
  DeployTemplate
  
  .INPUTS
  DeployTemplate - The name of DeployTemplate

  .OUTPUTS
  None
  
  .EXAMPLE
  DeployTemplate

  .EXAMPLE
  DeployTemplate


#>
function DeployTemplate() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $DeploymentName
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $TemplateFile
        ,
        [Parameter(Mandatory = $true)]
        [string]
        $TemplateParameterFile
    )

    Write-Verbose 'DeployTemplate: Starting'

    # get tenantId via Get-AzureRmSubscription
    # get objectId via $(Get-AzureRmADUser -UserPrincipalName '{imran.qureshi@healthcatalyst.com}').Id

    # Create or update the resource group using the specified template file and template parameters file
    New-AzureRmResourceGroupDeployment -Name "$DeploymentName" `
        -ResourceGroupName "fabrickubernetes2" `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $TemplateParameterFile `
        -Force -Verbose

    Write-Verbose 'DeployTemplate: Done'
}


Export-ModuleMember -Function "DeployTemplate"