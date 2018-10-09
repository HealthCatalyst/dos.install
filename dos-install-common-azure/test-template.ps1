$filename = "TODO"
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

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Integration Tests" -Tags 'Integration' {
    It "TestMethod" {
    }
}