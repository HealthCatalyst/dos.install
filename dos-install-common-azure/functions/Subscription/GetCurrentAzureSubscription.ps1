<#
.SYNOPSIS
GetCurrentAzureSubscription

.DESCRIPTION
GetCurrentAzureSubscription

.INPUTS
GetCurrentAzureSubscription - The name of GetCurrentAzureSubscription

.OUTPUTS
None

.EXAMPLE
GetCurrentAzureSubscription

.EXAMPLE
GetCurrentAzureSubscription


#>
function GetCurrentAzureSubscription()
{
    [CmdletBinding()]
    param
    (
    )

    Write-Verbose 'GetCurrentAzureSubscription: Starting'
    #Create an hashtable variable
    [hashtable]$Return = @{}

    $subscriptionName = $(az account show --query "name"  --output tsv)
    $subscriptionId = $(az account show --query "id" --output tsv)

    Write-Information -MessageData "Current SubscriptionId: ${subscriptionId}"

    $Return.AKS_SUBSCRIPTION_NAME = "$subscriptionName"
    $Return.AKS_SUBSCRIPTION_ID = "$subscriptionId"
    $Return.IS_CAFE_ENVIRONMENT = $($subscriptionName -match "CAFE" )
    Write-Verbose 'GetCurrentAzureSubscription: Done'
    return $Return

}

Export-ModuleMember -Function 'GetCurrentAzureSubscription'