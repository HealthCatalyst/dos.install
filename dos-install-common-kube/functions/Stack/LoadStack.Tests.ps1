<#
  .SYNOPSIS
  LoadStack
  
  .DESCRIPTION
  LoadStack
  
  .INPUTS
  LoadStack - The name of LoadStack

  .OUTPUTS
  None
  
  .EXAMPLE
  LoadStack

  .EXAMPLE
  LoadStack


#>
function LoadStack() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $namespace
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $baseUrl
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $appfolder
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $config
        ,
        $isAzure
        ,
        [string]
        $externalIp
        ,
        [string]
        $internalIp
        ,
        [string]
        $externalSubnetName
        ,
        [string]
        $internalSubnetName
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [bool] 
        $local
    )

    Write-Verbose 'LoadStack: Starting'

    [hashtable]$Return = @{} 

    if ([string]::IsNullOrWhiteSpace($(kubectl get namespace $namespace --ignore-not-found=true))) {
        Write-Information -MessageData "namespace $namespace does not exist so creating it"
        kubectl create namespace $namespace
    }

    Write-Information -MessageData "Installing stack $($config.name) version $($config.version) from $configpath"

    foreach ($secret in $($config.secrets.password)) {
        GenerateSecretPassword -secretname "$secret" -namespace "$namespace"
    }
    foreach ($secret in $($config.secrets.value)) {
        # AskForSecretValue -secretname "$secret" -prompt "Client Certificate hostname" -namespace "$namespace"        
        if ($secret -is [String]) {
            AskForSecretValue -secretname "$secret" -prompt "Client Certificate hostname" -namespace "$namespace"
        }
        else {
            $sourceSecretName = $($secret.valueFromSecret.name)
            $sourceSecretNamespace = $($secret.valueFromSecret.namespace)
            $value = ReadSecretValue -secretname $sourceSecretName -namespace $sourceSecretNamespace
            Write-Information -MessageData "Setting secret [$($secret.name)] to secret [$sourceSecretName] in namespace [$sourceSecretNamespace] with value [$value]"
            SaveSecretValue -secretname "$($secret.name)" -valueName "value" -value $value -namespace "$namespace"
        }
    }

    if ($namespace -ne "kube-system") {
        CleanOutNamespace -namespace $namespace
    }

    $customerid = ReadSecretValue -secretname customerid
    $customerid = $customerid.ToLower().Trim()
    Write-Information -MessageData "Customer ID: $customerid"

    Write-Information -MessageData "EXTERNALSUBNET: $externalSubnetName"
    Write-Information -MessageData "EXTERNALIP: $externalIp"
    Write-Information -MessageData "INTERNALSUBNET: $internalSubnetName"
    Write-Information -MessageData "INTERNALIP: $internalIp"

    $runOnMaster = $false

    [hashtable]$tokens = @{ 
        "CUSTOMERID"         = $customerid;
        "EXTERNALSUBNET"     = "$externalSubnetName";
        "EXTERNALIP"         = "$externalIp";
        "#REPLACE-RUNMASTER" = "$runOnMaster";
        "INTERNALSUBNET"     = "$internalSubnetName";
        "INTERNALIP"         = "$internalIp";
    }

    DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "dns" -tokens $tokens -resources $($config.resources.dns) -local $local

    DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "configmaps" -tokens $tokens -resources $($config.resources.configmaps) -local $local

    DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "roles" -tokens $tokens -resources $($config.resources.roles) -local $local

    if ($isAzure) {
        DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "volumes/azure" -tokens $tokens -resources $($config.resources.volumes.azure) -local $local
    }
    else {
        DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "volumes/onprem" -tokens $tokens -resources $($config.resources.volumes.onprem) -local $local
    }

    DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "volumeclaims" -tokens $tokens -resources $($config.resources.volumeclaims) -local $local

    DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "pods" -tokens $tokens -resources $($config.resources.pods) -local $local

    DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "services/cluster" -tokens $tokens -resources $($config.resources.services.cluster) -local $local

    DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "services/external" -tokens $tokens -resources $($config.resources.services.external) -local $local

    DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "ingress/http" -tokens $tokens -resources $($config.resources.ingress.http) -local $local

    if ($isAzure) {
        DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "ingress/tcp/azure" -tokens $tokens -resources $($config.resources.ingress.tcp.azure) -local $local
    }
    else {
        DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "ingress/tcp/onprem" -tokens $tokens -resources $($config.resources.ingress.tcp.onprem) -local $local
    }

    if ($(HasProperty -object $($config.resources.ingress) "jobs")) {
        DeployYamlFiles -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -folder "jobs" -tokens $tokens -resources $($config.resources.ingress.jobs) -local $local
    }

    # DeploySimpleServices -namespace $namespace -baseUrl $baseUrl -appfolder $appfolder -tokens $tokens -resources $($config.resources.ingress.simpleservices)

    WaitForPodsInNamespace -namespace $namespace -interval 5

    Write-Verbose 'LoadStack: Done'
    return $Return

}

Export-ModuleMember -Function "LoadStack"