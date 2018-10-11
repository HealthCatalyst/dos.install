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
        [string] $baseUrl
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()] 
        $config
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [bool] $local
    )

    Write-Verbose 'SetupLoadBalancer: Starting'

    $AKS_IP_WHITELIST = ""

    $AKS_PERS_RESOURCE_GROUP = $config.azure.resourceGroup
    $AKS_PERS_LOCATION = $config.azure.location

    $customerid = $config.customerid

    if ([string]::IsNullOrWhiteSpace($customerid)) {
        # https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/
        throw "customerid is null in config"
    }

    $customerid = $customerid.ToLower().Trim()
    Write-Host "Customer ID: $customerid"

    $ingressExternalType = $config.ingress.external.type
    $ingressInternalType = $config.ingress.internal.type

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

    $AKS_IP_WHITELIST = $config.ingress.external.whitelist

    Write-Host "Found vnet info from secret: vnet: $AKS_VNET_NAME, subnet: $AKS_SUBNET_NAME, subnetResourceGroup: $AKS_SUBNET_RESOURCE_GROUP"

    if ($ingressExternalType -eq "whitelist") {
        Write-Host "Whitelist: $AKS_IP_WHITELIST"

        SaveSecretValue -secretname whitelistip -valueName iprange -value "${AKS_IP_WHITELIST}"
    }

    # delete existing containers
    kubectl delete 'pods,services,configMaps,deployments,ingress' -l k8s-traefik=traefik -n kube-system --ignore-not-found=true

    # set Google DNS servers to resolve external  urls
    # http://blog.kubernetes.io/2017/04/configuring-private-dns-zones-upstream-nameservers-kubernetes.html
    kubectl delete -f "$baseUrl/loadbalancer/dns/upstream.yaml" --ignore-not-found=true
    Start-Sleep -Seconds 10
    kubectl create -f "$baseUrl/loadbalancer/dns/upstream.yaml"
    # to debug dns: https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/#inheriting-dns-from-the-node

    kubectl delete ServiceAccount traefik-ingress-controller-serviceaccount -n kube-system --ignore-not-found=true

    if ($($config.ssl) ) {
        # if the SSL cert is not set in kube secrets then ask for the files
        # ask for tls cert files
        $AKS_SSL_CERT_FOLDER = $($config.ssl_folder)
        if ((!(Test-Path -Path "$AKS_SSL_CERT_FOLDER"))) {
            Write-Error "SSL Folder does not exist: $AKS_SSL_CERT_FOLDER"
        }     

        $AKS_SSL_CERT_FOLDER_UNIX_PATH = (($AKS_SSL_CERT_FOLDER -replace "\\", "/")).ToLower().Trim("/")    

        kubectl delete secret traefik-cert-ahmn -n kube-system --ignore-not-found=true

        if ($($config.ssl_merge_intermediate_cert)) {
            # download the intermediate certificate and append to certificate
            $intermediatecert = $(Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/intermediate.crt").Content
            $sitecert = Get-Content "$AKS_SSL_CERT_FOLDER\tls.crt" -Raw 

            $siteplusintermediatecert = $sitecert + $intermediatecert

            $siteplusintermediatecert | Out-File -FilePath "$AKS_SSL_CERT_FOLDER\tlsplusintermediate.crt"

            Write-Host "Storing TLS certs plus intermediate cert from $AKS_SSL_CERT_FOLDER_UNIX_PATH as kubernetes secret"
            kubectl create secret generic traefik-cert-ahmn -n kube-system --from-file="$AKS_SSL_CERT_FOLDER_UNIX_PATH/tlsplusintermediate.crt" --from-file="$AKS_SSL_CERT_FOLDER_UNIX_PATH/tls.key"
        }
        else {
            Write-Host "Storing TLS certs from $AKS_SSL_CERT_FOLDER_UNIX_PATH as kubernetes secret"
            kubectl create secret generic traefik-cert-ahmn -n kube-system --from-file="$AKS_SSL_CERT_FOLDER_UNIX_PATH/tls.crt" --from-file="$AKS_SSL_CERT_FOLDER_UNIX_PATH/tls.key"                
        }
    }
    else {
        Write-Host "SSL option was not specified in the deployment config: $($config.ssl)"
    }

    Write-Host "baseUrl: $baseUrl"

    $externalSubnetName = ""
    if ($($config.ingress.external.subnet)) {
        $externalSubnetName = $($config.ingress.external.subnet);
    }
    elseif ($($config.networking.subnet)) {
        $externalSubnetName = $($config.networking.subnet);
    }

    $externalIp = ""
    if ($($config.ingress.external.ipAddress)) {
        $externalIp = $($config.ingress.external.ipAddress);
    }
    elseif ("$($config.ingress.external.type)" -ne "vnetonly") {
        Write-Host "Setting up a public load balancer"

        $ipResourceGroup = $AKS_PERS_RESOURCE_GROUP
        $publicIpName = "IngressPublicIP"
        $externalip = Get-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup
        if ([string]::IsNullOrWhiteSpace($externalip)) {
            New-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName ipResourceGroup -AllocationMethod Static -Location $AKS_PERS_LOCATION
            $externalip = Get-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ipResourceGroup
        }  
        Write-Host "Using Public IP: [$externalip]"
    }

    $internalSubnetName = ""
    if ($($config.ingress.internal.subnet)) {
        $internalSubnetName = $($config.ingress.internal.subnet);
    }
    elseif ($($config.networking.subnet)) {
        $internalSubnetName = $($config.networking.subnet);
    }

    $internalIp = ""
    if ($($config.ingress.internal.ipAddress)) {
        $internalIp = $($config.ingress.internal.ipAddress);
    }

    LoadLoadBalancerStack -baseUrl $baseUrl -ssl $($config.ssl) `
        -ingressInternalType "$ingressInternalType" -ingressExternalType "$ingressExternalType" `
        -customerid $customerid -isOnPrem $false `
        -externalSubnetName "$externalSubnetName" -externalIp "$externalip" `
        -internalSubnetName "$internalSubnetName" -internalIp "$internalIp" `
        -local $local

        # setting up traefik
    # https://github.com/containous/traefik/blob/master/docs/user-guide/kubernetes.md

    Write-Verbose "Calling GetLoadBalancerIPs"
    $loadBalancerIPResult = GetLoadBalancerIPs
    $EXTERNAL_IP = $loadBalancerIPResult.ExternalIP
    $INTERNAL_IP = $loadBalancerIPResult.InternalIP
    Write-Verbose "Back from GetLoadBalancerIPs"

    if ($($config.ingress.fixloadbalancer)) {
        FixLoadBalancers -resourceGroup $AKS_PERS_RESOURCE_GROUP
    }

    # if($($config.ingress.loadbalancerconfig)){
    #     MoveInternalLoadBalancerToIP -subscriptionId $($(GetCurrentAzureSubscription).AKS_SUBSCRIPTION_ID) -resourceGroup $AKS_PERS_RESOURCE_GROUP `
    #                                 -subnetResourceGroup $config.ingress.loadbalancerconfig.subnet_resource_group -vnetName $config.ingress.loadbalancerconfig.vnet `
    #                                 -subnetName $config.ingress.loadbalancerconfig.subnet -newIpAddress $config.ingress.loadbalancerconfig.privateIpAddress
    # }

    $dnsrecordname = $($config.dns.name)

    SaveSecretValue -secretname "dnshostname" -valueName "value" -value $dnsrecordname

    if ($($config.dns.create_dns_entries)) {
        SetupDNS -dnsResourceGroup $DNS_RESOURCE_GROUP -dnsrecordname $dnsrecordname -externalIP $EXTERNAL_IP 
    }
    else {
        Write-Host "To access the urls from your browser, add the following entries in your c:\windows\system32\drivers\etc\hosts file"
        Write-Host "$EXTERNAL_IP $dnsrecordname"
    }        

    Write-Verbose 'SetupLoadBalancer: Done'

}

Export-ModuleMember -Function "SetupLoadBalancer"