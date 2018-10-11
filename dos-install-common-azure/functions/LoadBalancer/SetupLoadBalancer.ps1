<#
  .SYNOPSIS
  SetupLoadBalancer

  .DESCRIPTION
  SetupLoadBalancer

  .INPUTS
  SetupLoadBalancer - The name of SetupLoadBalancer

  .OUTPUTS
  None

  .EXAMPLE
  SetupLoadBalancer

  .EXAMPLE
  SetupLoadBalancer


#>
function SetupLoadBalancer() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $baseUrl
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $config
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [bool]
        $local
    )

    Write-Verbose 'SetupLoadBalancer: Starting'

    [string] $resourceGroup = $config.azure.resourceGroup
    AssertStringIsNotNullOrEmpty $resourceGroup

    [string] $location = $config.azure.location
    AssertStringIsNotNullOrEmpty $location

    [string] $customerid = $config.customerid
    AssertStringIsNotNullOrEmpty $customerid

    $customerid = $customerid.ToLower().Trim()
    Write-Verbose "Customer ID: $customerid"

    [string] $ingressExternalType = $config.ingress.external.type
    [string] $ingressInternalType = $config.ingress.internal.type

    if ([string]::IsNullOrWhiteSpace($ingressExternalType)) {
        # https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/
        throw "ingress.external.type is null in config"
    }
    if ([string]::IsNullOrWhiteSpace($ingressInternalType)) {
        throw "ingress.internal.type is null in config"
    }
    if ([string]::IsNullOrWhiteSpace($($config.dns.name))) {
        throw "dns.name is null in config"
    }

    [string] $whiteListIp = $config.ingress.external.whitelist

    Write-Verbose "Found vnet info from secret: vnet: $AKS_VNET_NAME, subnet: $AKS_SUBNET_NAME, subnetResourceGroup: $AKS_SUBNET_RESOURCE_GROUP"

    if ($ingressExternalType -eq "whitelist") {
        Write-Host "Whitelist: $whiteListIp"

        SaveSecretValue -secretname whitelistip -valueName iprange -value "${whiteListIp}"
    }

    if ($($config.ssl) ) {
        # if the SSL cert is not set in kube secrets then ask for the files
        # ask for tls cert files
        [string] $sslCertFolder = $($config.ssl_folder)
        if ((!(Test-Path -Path "$sslCertFolder"))) {
            Write-Error "SSL Folder does not exist: $sslCertFolder"
        }

        [string] $sslCertFolderUnixPath = (($sslCertFolder -replace "\\", "/")).ToLower().Trim("/")

        kubectl delete secret traefik-cert-ahmn -n kube-system --ignore-not-found=true

        if ($($config.ssl_merge_intermediate_cert)) {
            # download the intermediate certificate and append to certificate
            [string] $intermediatecert = $(Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/intermediate.crt").Content
            [string] $sitecert = Get-Content "$sslCertFolder\tls.crt" -Raw

            [string] $siteplusintermediatecert = $sitecert + $intermediatecert

            $siteplusintermediatecert | Out-File -FilePath "$sslCertFolder\tlsplusintermediate.crt"

            Write-Host "Storing TLS certs plus intermediate cert from $sslCertFolderUnixPath as kubernetes secret"
            kubectl create secret generic traefik-cert-ahmn -n kube-system --from-file="$sslCertFolderUnixPath/tlsplusintermediate.crt" --from-file="$sslCertFolderUnixPath/tls.key"
        }
        else {
            Write-Host "Storing TLS certs from $sslCertFolderUnixPath as kubernetes secret"
            kubectl create secret generic traefik-cert-ahmn -n kube-system --from-file="$sslCertFolderUnixPath/tls.crt" --from-file="$sslCertFolderUnixPath/tls.key"
        }
    }
    else {
        Write-Host "SSL option was not specified in the deployment config: $($config.ssl)"
    }

    [string] $externalSubnetName = ""
    if ($($config.ingress.external.subnet)) {
        $externalSubnetName = $($config.ingress.external.subnet);
    }
    elseif ($($config.networking.subnet)) {
        $externalSubnetName = $($config.networking.subnet);
    }

    [string] $externalIp = ""
    if ($($config.ingress.external.ipAddress)) {
        $externalIp = $($config.ingress.external.ipAddress);
    }
    elseif ("$($config.ingress.external.type)" -ne "vnetonly") {
        Write-Verbose "Setting up a public load balancer"

        [string] $ipResourceGroup = $resourceGroup
        [string] $publicIpName = "IngressPublicIP"
        $externalIpObject = Get-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup
        if ($externalIpObject -eq $null) {
            New-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName ipResourceGroup -AllocationMethod Static -Location $location
            $externalIpObject = Get-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup
        }
        $externalip = $externalIpObject.IpAddress
        Write-Host "Using Public IP: [$externalip]"
    }

    [string] $internalSubnetName = ""
    if ($($config.ingress.internal.subnet)) {
        $internalSubnetName = $($config.ingress.internal.subnet);
    }
    elseif ($($config.networking.subnet)) {
        $internalSubnetName = $($config.networking.subnet);
    }

    [string] $internalIp = ""
    if ($($config.ingress.internal.ipAddress)) {
        $internalIp = $($config.ingress.internal.ipAddress);
    }

    [bool] $ssl = $($($config.ssl) -eq "true")
    $packageUrl = "https://raw.githubusercontent.com/HealthCatalyst/helm.loadbalancer/master/fabricloadbalancer-1.0.0.tgz"
    InstallLoadBalancerHelmPackage `
        -packageUrl $packageUrl `
        -ssl $ssl `
        -ingressInternalType "$ingressInternalType" `
        -ingressExternalType "$ingressExternalType" `
        -customerid $customerid `
        -externalSubnet "$externalSubnetName" `
        -externalIp "$externalip" `
        -internalSubnet "$internalSubnetName" `
        -internalIp "$internalIp"

        # setting up traefik
    # https://github.com/containous/traefik/blob/master/docs/user-guide/kubernetes.md

    Write-Host "Checking load balancers"
    $loadBalancerIPResult = GetLoadBalancerIPs
    $externalIp = $loadBalancerIPResult.ExternalIP
    $internalIp = $loadBalancerIPResult.InternalIP

    Write-Host "IP for public loadbalancer: [$externalIp], private load balancer: [$internalIp]"

    if ($($config.ingress.fixloadbalancer)) {
        FixLoadBalancers -resourceGroup $resourceGroup
    }

    # if($($config.ingress.loadbalancerconfig)){
    #     MoveInternalLoadBalancerToIP -subscriptionId $($(GetCurrentAzureSubscription).AKS_SUBSCRIPTION_ID) -resourceGroup $resourceGroup `
    #                                 -subnetResourceGroup $config.ingress.loadbalancerconfig.subnet_resource_group -vnetName $config.ingress.loadbalancerconfig.vnet `
    #                                 -subnetName $config.ingress.loadbalancerconfig.subnet -newIpAddress $config.ingress.loadbalancerconfig.privateIpAddress
    # }

    [string] $dnsrecordname = $($config.dns.name)

    SaveSecretValue -secretname "dnshostname" -valueName "value" -value $dnsrecordname -namespace "default"

    if ($($config.dns.create_dns_entries)) {
        SetupDNS -dnsResourceGroup $DNS_RESOURCE_GROUP -dnsrecordname $dnsrecordname -externalIP $externalIp
    }
    else {
        Write-Host "To access the urls from your browser, add the following entries in your c:\windows\system32\drivers\etc\hosts file"
        Write-Host "$externalIp $dnsrecordname"
    }

    Write-Verbose 'SetupLoadBalancer: Done'
}

Export-ModuleMember -Function "SetupLoadBalancer"