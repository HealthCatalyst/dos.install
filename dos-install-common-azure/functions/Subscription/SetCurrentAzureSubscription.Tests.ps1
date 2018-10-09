$filename = "SetCurrentAzureSubscription.ps1"
$module = "dos-install-common-azure"

$mockConfig = @"
{
    "azure": {
        "subscription": "Health Catalyst - Fabric",
        "resourceGroup": "fabrickubernetes",
        "location": "eastus"
    }
}
"@ | ConvertFrom-Json

Describe "$filename Unit Tests" -Tags 'Integration' {
    It "Sets Secret" {
        SetCurrentAzureSubscription -subscriptionName $($mockConfig.azure.subscription)
    }
}