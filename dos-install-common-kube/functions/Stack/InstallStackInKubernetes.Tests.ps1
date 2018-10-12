$filename = $($(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.ps1",""))

Describe "$filename Unit Tests" -Tags 'Unit' {
    It "TestMethod" {
    }
}

Describe "$filename Integration Tests" -Tags 'Integration' {
    It "Can Install FabricRealtime Stack" {
        $packageUrl = "https://raw.githubusercontent.com/HealthCatalyst/helm.realtime/master/fabricrealtime-1.0.0.tgz"

        InstallStackInKubernetes `
            -namespace "fabricrealtime" `
            -package "fabricrealtime" `
            -packageUrl $packageUrl `
            -Ssl $false `
            -customerid "test" `
            -ExternalIP "104.42.148.128" `
            -InternalIP "" `
            -ExternalSubnet "" `
            -InternalSubnet "" `
            -IngressInternalType "public" `
            -IngressExternalType "public" `
            -Verbose
    }
}