$filename = $($(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1",""))

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Integration Tests" -Tags @('Integration','Cluster') {
    It "Deploys cluster Template" {
        Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose
        CleanResourceGroup -DeploymentName "CleanCluster" -TemplateFile ..\azure\arm\cluster.json -TemplateParameterFile ..\..\clientenvironments\fabrickubernetes2\cluster.parameters.json -Verbose
    }
}
