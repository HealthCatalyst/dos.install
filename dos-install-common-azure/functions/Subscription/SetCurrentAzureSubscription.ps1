<#
  .SYNOPSIS
  SetCurrentAzureSubscription
  
  .DESCRIPTION
  SetCurrentAzureSubscription
  
  .INPUTS
  SetCurrentAzureSubscription - The name of SetCurrentAzureSubscription

  .OUTPUTS
  None
  
  .EXAMPLE
  SetCurrentAzureSubscription

  .EXAMPLE
  SetCurrentAzureSubscription


#>
function SetCurrentAzureSubscription() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string] 
        $subscriptionName
    )

    Write-Verbose 'SetCurrentAzureSubscription: Starting'

    #Create an hashtable variable 
    [hashtable]$Return = @{} 

    $currentsubscriptionName = $(Get-AzureRmContext).Subscription.Name
    $currentsubscriptionId = $(Get-AzureRmContext).Subscription.Id

    Write-Information -MessageData "Current SubscriptionId: ${currentsubscriptionId}, newSubcriptionID: ${subscriptionId}"

    Get-AzureRmSubscription

    if ($subscriptionName -eq $currentsubscriptionName -or ($subscriptionName -eq $currentsubscriptionId)) {
        # nothing to do
        Write-Information -MessageData "Subscription is already set properly so no need to anything"
    }
    else {
        Write-Information -MessageData "Setting subscription to $subscriptionName"
        Select-AzureRmSubscription -SubscriptionName $subscriptionName
        $currentsubscriptionName = $(Get-AzureRmContext).Subscription.Name
        $currentsubscriptionId = $(Get-AzureRmContext).Subscription.Id            
    }

    # az account get-access-token --subscription $currentsubscriptionId

    Write-Verbose 'SetCurrentAzureSubscription: Done'

    return $Return  
}

Export-ModuleMember -Function "SetCurrentAzureSubscription"