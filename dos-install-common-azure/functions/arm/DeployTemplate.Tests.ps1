$filename = $($(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1",""))

echo "filename: $filename"

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Integration Tests" -Tags 'Integration' {
    It "Deploys cluster Template" {
        Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose
        DeployTemplate -DeploymentName "CreateCluster" -TemplateFile ..\azure\arm\cluster.json -TemplateParameterFile ..\..\clientenvironments\fabrickubernetes2\cluster.parameters.json -Verbose
    }

    It "Deploys ACS Template" {
        Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose
        DeployTemplate -DeploymentName "DeployACS" -TemplateFile ..\azure\arm\acs.json -TemplateParameterFile ..\..\clientenvironments\fabrickubernetes2\acs.parameters.json -Verbose
    }
}