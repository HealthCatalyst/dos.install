# $here = Split-Path -Parent $MyInvocation.MyCommand.Path
$filename = "function-SetStorageAccountNameIntoSecret.ps1"

# region Mock data
$mockConfig = @"
{
    "kubectl": {
        "version": "1.11.0"
    },
    "kubernetes": {
        "version": "1.11.2"
    },
    "azcli": {
        "version": "2.0.45"
    },
    "azure": {
        "subscription": "Health Catalyst - Fabric",
        "resourceGroup": "fabrickubernetes",
        "location": "eastus",
        "create_windows_containers": false,
        "use_azure_networking": true,
        "acs_engine": {
            "version": "0.15.0"
        },
        "masterVMSize": "Standard_DS2_v2",
        "workerVMSize": "Standard_DS2_v2"
    },
    "service_principal": {
        "name": "",
        "delete_if_exists": true
    },
    "storage_account": {
        "delete_if_exists": false
    },
    "local_folder": "c:\\kubernetes",
    "customerid": "hcut",
    "ssl": false,
    "allow_kubectl_from_outside_vnet": true,
    "ingress": {
        "external": {
            "type": "public"
        },
        "internal": {
            "type": "public"
        }
    },
    "networking": {
        "vnet": "kubnettest",
        "subnet": "kubsubnet",
        "subnet_resource_group": "Imran"
    },
    "network_security_group": {
        "name": "",
        "create_nsg_rules": false
    },
    "dns": {
        "name": "fabrickubernetes.healthcatalyst.net",
        "create_dns_entries": false,
        "dns_resource_group": "dns"
    }
}
"@ | ConvertFrom-Json
# end region

Describe "$filename Tests" {
    Context "Unit Tests" {

        It "Sets Secret" {
            mock -CommandName "GetStorageAccountName" -MockWith {
                return "foo"
            }
            mock -CommandName "AzureRmStorageAccountKey" -MockWith {
                return "mykey"
            }
            mock -CommandName "DeleteSecret" -MockWith {

            }
            mock -CommandName "CreateSecretWithMultipleValues" -MockWith {
                
            }
        }
    }

    Context "Integration Tests" {
        It "sets secret" {
            SetStorageAccountNameIntoSecret -config $mockConfig | Should Be $true
        }    
    }
}