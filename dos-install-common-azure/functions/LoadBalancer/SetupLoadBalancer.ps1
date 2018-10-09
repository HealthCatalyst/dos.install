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

    LoginToAzure

    SetCurrentAzureSubscription -subscriptionName $($config.azure.subscription)

    # $AKS_SUBSCRIPTION_ID = $userInfo.AKS_SUBSCRIPTION_ID
    # $IS_CAFE_ENVIRONMENT = $userInfo.IS_CAFE_ENVIRONMENT

    $AKS_PERS_RESOURCE_GROUP = $config.azure.resourceGroup
    $AKS_PERS_LOCATION = $config.azure.location

    # Get location name from resource group
    $AKS_PERS_LOCATION = (Get-AzureRmResourceGroup -Name "$AKS_PERS_RESOURCE_GROUP").Location
    Write-Host "Using location: [$AKS_PERS_LOCATION]"

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
      # https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/
      throw "ingress.internal.type is null in config"
  }
    $AKS_IP_WHITELIST = $config.ingress.external.whitelist

    # read the vnet and subnet info from kubernetes secret
    $AKS_VNET_NAME = $config.networking.vnet
    $AKS_SUBNET_NAME = $config.networking.subnet
    $AKS_SUBNET_RESOURCE_GROUP = $config.networking.subnet_resource_group

    Write-Host "Found vnet info from secret: vnet: $AKS_VNET_NAME, subnet: $AKS_SUBNET_NAME, subnetResourceGroup: $AKS_SUBNET_RESOURCE_GROUP"

    if ($ingressExternalType -eq "whitelist") {
        Write-Host "Whitelist: $AKS_IP_WHITELIST"

        SaveSecretValue -secretname whitelistip -valueName iprange -value "${AKS_IP_WHITELIST}"
    }

    Write-Host "Setting up Network Security Group for the subnet"

    # setup network security group
    $AKS_PERS_NETWORK_SECURITY_GROUP = "$($AKS_PERS_RESOURCE_GROUP.ToLower())-nsg"

    if ([string]::IsNullOrWhiteSpace($(Get-AzureRmNetworkSecurityGroup -Name $AKS_PERS_NETWORK_SECURITY_GROUP -ResourceGroupName "$AKS_PERS_RESOURCE_GROUP").Name)) {

        Write-Host "Creating the Network Security Group for the subnet"
        New-AzureRmNetworkSecurityGroup -Name $AKS_PERS_NETWORK_SECURITY_GROUP -ResourceGroupName $AKS_PERS_RESOURCE_GROUP
    }
    else {
        Write-Host "Network Security Group already exists: $AKS_PERS_NETWORK_SECURITY_GROUP"
    }

    if ($($config.network_security_group.create_nsg_rules)) {
        Write-Host "Adding or updating rules to Network Security Group for the subnet"
        $sourceTagForAdminAccess = "VirtualNetwork"
        if ($($config.allow_kubectl_from_outside_vnet)) {
            $sourceTagForAdminAccess = "Internet"
            Write-Host "Enabling admin access to cluster from Internet"
        }

        $sourceTagForHttpAccess = "Internet"
        if (![string]::IsNullOrWhiteSpace($AKS_IP_WHITELIST)) {
            $sourceTagForHttpAccess = $AKS_IP_WHITELIST
        }

        DeleteNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP -rulename "HttpPort"
        DeleteNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP -rulename "HttpsPort"

        SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
            -rulename "allow_kube_tls" `
            -ruledescription "allow kubectl and HTTPS access from ${sourceTagForAdminAccess}." `
            -sourceTag "${sourceTagForAdminAccess}" -port 443 -priority 100 

        SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
            -rulename "allow_http" `
            -ruledescription "allow HTTP access from ${sourceTagForAdminAccess}." `
            -sourceTag "${sourceTagForAdminAccess}" -port 80 -priority 101
          
        SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
            -rulename "allow_ssh" `
            -ruledescription "allow SSH access from ${sourceTagForAdminAccess}." `
            -sourceTag "${sourceTagForAdminAccess}" -port 22 -priority 104

        SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
            -rulename "allow_mysql" `
            -ruledescription "allow MySQL access from ${sourceTagForAdminAccess}." `
            -sourceTag "${sourceTagForAdminAccess}" -port 3306 -priority 205
          
        # if we already have opened the ports for admin access then we're not allowed to add another rule for opening them
        if (($sourceTagForHttpAccess -eq "Internet") -and ($sourceTagForAdminAccess -eq "Internet")) {
            Write-Host "Since we already have rules open port 80 and 443 to the Internet, we do not need to create separate ones for the Internet"
        }
        else {
            if ($($config.ingress.external) -ne "vnetonly") {
                SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
                    -rulename "HttpPort" `
                    -ruledescription "allow HTTP access from ${sourceTagForHttpAccess}." `
                    -sourceTag "${sourceTagForHttpAccess}" -port 80 -priority 500
  
                SetNetworkSecurityGroupRule -resourceGroup $AKS_PERS_RESOURCE_GROUP -networkSecurityGroup $AKS_PERS_NETWORK_SECURITY_GROUP `
                    -rulename "HttpsPort" `
                    -ruledescription "allow HTTPS access from ${sourceTagForHttpAccess}." `
                    -sourceTag "${sourceTagForHttpAccess}" -port 443 -priority 501
            }
        }

        $nsgid = az network nsg list --resource-group ${AKS_PERS_RESOURCE_GROUP} --query "[?name == '${AKS_PERS_NETWORK_SECURITY_GROUP}'].id" -o tsv
        Write-Host "Found ID for ${AKS_PERS_NETWORK_SECURITY_GROUP}: $nsgid"

        Write-Host "Setting NSG into subnet"
        az network vnet subnet update -n "${AKS_SUBNET_NAME}" -g "${AKS_SUBNET_RESOURCE_GROUP}" --vnet-name "${AKS_VNET_NAME}" --network-security-group "$nsgid" --query "provisioningState" -o tsv
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
            $publicIp = New-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName ipResourceGroup -AllocationMethod Static -Location $AKS_PERS_LOCATION
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