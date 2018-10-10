<#
  .SYNOPSIS
  CleanResourceGroup
  
  .DESCRIPTION
  CleanResourceGroup
  
  .INPUTS
  CleanResourceGroup - The name of CleanResourceGroup

  .OUTPUTS
  None
  
  .EXAMPLE
  CleanResourceGroup

  .EXAMPLE
  CleanResourceGroup


#>
function CleanResourceGroup()
{
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

    Write-Verbose 'CleanResourceGroup: Starting'

    # get tenantId via Get-AzureRmSubscription
    # get objectId via $(Get-AzureRmADUser -UserPrincipalName '{imran.qureshi@healthcatalyst.com}').Id

    # Create or update the resource group using the specified template file and template parameters file
    New-AzureRmResourceGroupDeployment -Name "$DeploymentName" `
        -ResourceGroupName "fabrickubernetes2" `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $TemplateParameterFile `
        -Mode Complete `
        -Force -Verbose

  Write-Verbose 'CleanResourceGroup: Done'
}

Export-ModuleMember -Function "CleanResourceGroup"