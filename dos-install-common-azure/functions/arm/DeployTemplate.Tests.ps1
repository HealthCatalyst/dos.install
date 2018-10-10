$filename = $($(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1",""))

echo "filename: $filename"

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Cluster Integration Tests" -Tags @('Integration','Cluster') {
    It "Deploys cluster Template" {
        Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose
        DeployTemplate -DeploymentName "CreateCluster" -TemplateFile ..\azure\arm\cluster.json -TemplateParameterFile ..\..\clientenvironments\fabrickubernetes2\cluster.parameters.json -Verbose
    }
}

Describe "$filename ACS Integration Tests" -Tags @('Integration','ACS') {
    It "Deploys cluster Template" {
        Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose
        DeployTemplate -DeploymentName "DeployACS" -TemplateFile ..\azure\arm\acs.json -TemplateParameterFile ..\..\clientenvironments\fabrickubernetes2\acs.parameters.json -Verbose
    }
}

Describe "$filename AKS Integration Tests" -Tags @('Integration','AKS') {
    It "Deploys cluster Template" {
        Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose
        DeployTemplate -DeploymentName "DeployAKS" -TemplateFile ..\azure\arm\aks.json -TemplateParameterFile ..\..\clientenvironments\fabrickubernetes2\aks.parameters.json -Verbose
    }
}