# $here = Split-Path -Parent $MyInvocation.MyCommand.Path
$filename = "SetStorageAccountNameIntoSecret.ps1"
$module = "dos-install-common-azure"

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

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "Sets Secret" {
        # https://www.red-gate.com/simple-talk/sysadmin/powershell/practical-powershell-unit-testing-mock-objects/

        # Arrange
        mock -CommandName "GetStorageAccountName" -MockWith {
            Write-Host "Mock GetStorageAccountName"
            return @{
                StorageAccountName = "foo"
            }
        } -ModuleName $module

        mock -CommandName "Get-AzureRmStorageAccountKey" -MockWith {
            Write-Host "Mock Get-AzureRmStorageAccountKey"
            return @{
                Value = @("mykey")
            }
        } -Module $module

        mock -CommandName "DeleteSecret" -MockWith {
            [CmdletBinding()]
            param(
                [parameter (Mandatory = $true) ]
                [string]
                $secretname
                ,
                [parameter (Mandatory = $true) ]
                [string] 
                $namespace                
            )
            Write-Host "Mock DeleteSecret: $secretname"
            $secretname | Should Be "azure-secret"
            $namespace | Should Be "default"
        } -ModuleName $module

        mock -CommandName "CreateSecretWithMultipleValues" -MockWith {
            [CmdletBinding()]
            param
            (
              [parameter (Mandatory = $true) ]
              [string]
              $secretname
              ,
              [parameter (Mandatory = $true) ]
              [string] 
              $namespace
              ,
              [parameter (Mandatory = $true) ]
              [string] 
              $secret1
              ,
              [parameter (Mandatory = $true) ]
              [string] 
              $secret2
              ,    
              [parameter (Mandatory = $true) ]
              [string] 
              $secret3
            )            
            Write-Host "Mock CreateSecretWithMultipleValues: $secretname, secret1=$secret1, secret2=$secret2, secret3=$secret3"
            $secretname | Should Be "azure-secret"
            $secret1 | Should Be "resourcegroup=fabrickubernetes"            
            $secret2 | Should Be "azurestorageaccountname=foo"            
            $secret3 | Should Be "azurestorageaccountkey=mykey"            
        } -ModuleName $module

        # Act
        $VerbosePreference = "Continue"
        SetStorageAccountNameIntoSecret -resourceGroup "fabrickubernetes" -customerid "hcut"

        # Assert
        Assert-VerifiableMocks
    }

}

Describe "$filename Integration Tests" -Tags 'Integration' {
    It "sets secret" {
        SetStorageAccountNameIntoSecret -resourceGroup "fabrickubernetes" -customerid "hcut" | Should Be $true
    }      
}
