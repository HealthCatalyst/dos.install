$filename = "SetupLoadBalancer.ps1"
$module = "dos-install-common-azure"

$mockConfig = @"
{
    "customerid": "test",
    "azure": {
        "subscription": "Health Catalyst - Fabric",
        "resourceGroup": "fabrickubernetes",
        "location": "eastus"
    },
    "ingress": {
        "external": {
            "type": "public"
        },
        "internal": {
            "type": "public"
        }
    }    
}
"@ | ConvertFrom-Json

if($local){
    $GITHUB_URL = "."
    # $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/master"
}
else {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/master"
}

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Integration Tests" -Tags 'Integration' {
    It "TestMethod" {
        SetupLoadBalancer -baseUrl $GITHUB_URL -config $mockConfig -local $true
    }
}