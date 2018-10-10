$filename = $($(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1",""))

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Integration Tests" -Tags 'Integration' {
    It "Can Assign Permissions To ServicePrincipal" {
        Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose      
        AssignPermissionsToServicePrincipal -applicationId "2972711c-c80d-4a15-93cc-5c3ab8a5d2e9" -objectId "2972711c-c80d-4a15-93cc-5c3ab8a5d2e9" -Verbose
    }
}