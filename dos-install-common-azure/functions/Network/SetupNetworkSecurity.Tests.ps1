$filename = $($(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1",""))

$mockConfig = @"
{
    "azure": {
        "subscription": "PlatformStaff-DevTest",
        "resourceGroup": "hcut-acs-rg",
        "location": "westus"
    },
    "customerid" : "hcut",
    "ingress": {
        "external":{
            "type": "public"
        },
        "internal": {
            "type": "vnetonly",
            "ipAddress": "10.0.0.112",
            "subnet": "kubsubnet"
        }
    },
    "dns": {
        "name": "hcut.healthcatalyst.net",
        "create_dns_entries": false,
        "dns_resource_group": "dns"
    }        
}
"@ | ConvertFrom-Json

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Integration Tests" -Tags 'Integration' {
    It "Can Setup Network Security" {
        SetupNetworkSecurity -config $mockConfig
    }
}