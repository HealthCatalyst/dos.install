$filename = $($(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1",""))

echo "filename: $filename"

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Integration Tests" -Tags 'Integration' {
    It "Deploys Template" {
        Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose
        DeployTemplate -TemplateFile ..\azure\arm\acscluster.json -TemplateParameterFile ..\..\clientenvironments\fabrickubernetes2\parameters.json -Verbose
    }
}