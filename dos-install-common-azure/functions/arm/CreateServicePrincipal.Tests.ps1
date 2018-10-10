$filename = $($(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1",""))

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Integration Tests" -Tags 'Integration' {
    It "Create New Service Principal" {
        Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose      
        $result = CreateServicePrincipal -resourceGroup "fabrickubernetes2" -applicationName "fabrickubernetes2"
        Write-Host ($result | Out-String)
    }
}