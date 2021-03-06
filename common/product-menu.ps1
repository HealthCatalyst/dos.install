$versionmenucommon = "2018.06.06.01"

Write-Information -MessageData "Including product-menu.ps1 version $versionmenucommon"
function global:GetCommonMenuVersion() {
    return $versionmenucommon
}

function InstallProduct([ValidateNotNullOrEmpty()][string] $baseUrl, `
        [ValidateNotNullOrEmpty()][string] $namespace, `
        $isAzure ) {

    if ($isAzure) {
        # read deployment config
        $loadbalancerInfo = $(GetLoadBalancerIPs)
        $externalIP = $loadbalancerInfo.ExternalIP
        $internalIP = $loadbalancerInfo.InternalIP

        $loadbalancerExternal = "traefik-ingress-service-public"
        $loadbalancerInternal = "traefik-ingress-service-internal" 
    
        $internalSubnetName = $(kubectl get svc $loadbalancerInternal -n kube-system -o jsonpath="{.metadata.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-internal-subnet}")
        $externalSubnetName = $(kubectl get svc $loadbalancerExternal -n kube-system -o jsonpath="{.metadata.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-internal-subnet}")
    
        if (!$externalSubnetName) {$externalSubnetName = $internalSubnetName}
        if (!$internalSubnetName) {$internalSubnetName = $externalSubnetName}
    }
            
    $folder = $namespace.Replace("fabric", "")

    if ($namespace -eq "fabricrealtime") {
        InstallStack -namespace $namespace -baseUrl $baseUrl -appfolder $folder -isAzure $isAzure `
            -externalIp $externalIP -internalIp $internalIP `
            -externalSubnetName $externalSubnetName -internalSubnetName $internalSubnetName `
            -local $false
    }
    elseif ($namespace -eq "fabricnlp") {
        CreateNamespaceIfNotExists $namespace
        AskForPasswordAnyCharacters -secretname "smtprelaypassword" -prompt "Please enter SMTP relay password" -namespace $namespace
        $dnshostname = $(ReadSecretValue -secretname "dnshostname" -namespace "default")
        SaveSecretValue -secretname "nlpweb-external-url" -valueName "value" -value "nlp.$dnshostname" -namespace $namespace
        SaveSecretValue -secretname "jobserver-external-url" -valueName "value" -value "nlpjobs.$dnshostname" -namespace $namespace
        InstallStack -namespace $namespace -baseUrl $baseUrl -appfolder $folder -isAzure $isAzure `
            -externalIp $externalIP -internalIp $internalIP `
            -externalSubnetName $externalSubnetName -internalSubnetName $internalSubnetName                  `
            -local $false
    }
    elseif ($namespace -eq "fabricmachinelearning") {
        CreateNamespaceIfNotExists $namespace

        $serviceaccountsecretname="mlserviceaccount"
        $sqlserversecretname="mltestsqlserver"
        if ([string]::IsNullOrWhiteSpace($(kubectl get secret $serviceaccountsecretname -n $namespace -o jsonpath='{.data}' --ignore-not-found=true))) {

            $USERNAME = Read-Host "Service account user: (Default: $($env:USERNAME))"
            if ([string]::IsNullOrWhiteSpace($USERNAME)) {
                $USERNAME = $($env:USERNAME)
            }

            $AD_DOMAIN = Read-Host "Active Directory domain: (Default: $($env:USERDNSDOMAIN))"
            if ([string]::IsNullOrWhiteSpace($AD_DOMAIN)) {
                $AD_DOMAIN = $env:USERDNSDOMAIN
            }
        
            $AD_DOMAIN_SERVER = $($env:LOGONSERVER).Replace("\\", "")
            $AD_DOMAIN_SERVER = Read-Host "Active Directory domain server: (Default: $AD_DOMAIN_SERVER)"
            if ([string]::IsNullOrWhiteSpace($AD_DOMAIN_SERVER)) {
                $AD_DOMAIN_SERVER = $($env:LOGONSERVER).Replace("\\", "")
            }

            Do {$password = Read-Host -assecurestring -Prompt "Please enter your password for ${USERNAME}@${AD_DOMAIN}"} while ($($password.Length) -lt 1)
            $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

            $TEST_SQL_SERVER = "$env:computername.$env:userdnsdomain"
            $TEST_SQL_SERVER = Read-Host "Test SQL Server: (Default: $TEST_SQL_SERVER)"
            if ([string]::IsNullOrWhiteSpace($TEST_SQL_SERVER)) {
                $TEST_SQL_SERVER = "$env:computername.$env:userdnsdomain"
            }

            $secretvalues = @()
            $secretvalues += @{
                secretkey   = "user" 
                secretvalue = "$USERNAME"
            }
            $secretvalues += @{
                secretkey   = "password" 
                secretvalue = "$password"
            }
            $secretvalues += @{
                secretkey   = "domain" 
                secretvalue = "$AD_DOMAIN"
            }
            $secretvalues += @{
                secretkey   = "domainserver" 
                secretvalue = "$AD_DOMAIN_SERVER"
            }
            SaveMultipleSecretValues -namespace $namespace -secretname "$serviceaccountsecretname" -secretvalues $secretvalues

            SaveSecretValue -secretname "$sqlserversecretname" -valueName "value" -value "$TEST_SQL_SERVER" -namespace $namespace
        }
    
        InstallStack -namespace $namespace -baseUrl $baseUrl -appfolder $folder -isAzure $isAzure `
            -externalIp $externalIP -internalIp $internalIP `
            -externalSubnetName $externalSubnetName -internalSubnetName $internalSubnetName                  `
            -local $false
    }
    elseif ($namespace -eq "fabricehr") {
        CreateNamespaceIfNotExists $namespace

        $serviceaccountsecretname="ehrserviceaccount"
        $sqlserversecretname="ehrsqlserver"

        if ([string]::IsNullOrWhiteSpace($(kubectl get secret $serviceaccountsecretname -n $namespace -o jsonpath='{.data}' --ignore-not-found=true))) {

            $USERNAME = Read-Host "Service account user: (Default: $($env:USERNAME))"
            if ([string]::IsNullOrWhiteSpace($USERNAME)) {
                $USERNAME = $($env:USERNAME)
            }

            $AD_DOMAIN = Read-Host "Active Directory domain: (Default: $($env:USERDNSDOMAIN))"
            if ([string]::IsNullOrWhiteSpace($AD_DOMAIN)) {
                $AD_DOMAIN = $env:USERDNSDOMAIN
            }
        
            $AD_DOMAIN_SERVER = $($env:LOGONSERVER).Replace("\\", "")
            $AD_DOMAIN_SERVER = Read-Host "Active Directory domain server: (Default: $AD_DOMAIN_SERVER)"
            if ([string]::IsNullOrWhiteSpace($AD_DOMAIN_SERVER)) {
                $AD_DOMAIN_SERVER = $($env:LOGONSERVER).Replace("\\", "")
            }

            Do {$password = Read-Host -assecurestring -Prompt "Please enter your password for ${USERNAME}@${AD_DOMAIN}"} while ($($password.Length) -lt 1)
            $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

            $TEST_SQL_SERVER = "$env:computername.$env:userdnsdomain"
            $TEST_SQL_SERVER = Read-Host "Test SQL Server: (Default: $TEST_SQL_SERVER)"
            if ([string]::IsNullOrWhiteSpace($TEST_SQL_SERVER)) {
                $TEST_SQL_SERVER = "$env:computername.$env:userdnsdomain"
            }

            $secretvalues = @()
            $secretvalues += @{
                secretkey   = "user" 
                secretvalue = "$USERNAME"
            }
            $secretvalues += @{
                secretkey   = "password" 
                secretvalue = "$password"
            }
            $secretvalues += @{
                secretkey   = "domain" 
                secretvalue = "$AD_DOMAIN"
            }
            $secretvalues += @{
                secretkey   = "domainserver" 
                secretvalue = "$AD_DOMAIN_SERVER"
            }
            SaveMultipleSecretValues -namespace $namespace -secretname "$serviceaccountsecretname" -secretvalues $secretvalues

            SaveSecretValue -secretname "$sqlserversecretname" -valueName "value" -value "$TEST_SQL_SERVER" -namespace $namespace
        }
    
        InstallStack -namespace $namespace -baseUrl $baseUrl -appfolder $folder -isAzure $isAzure `
            -externalIp $externalIP -internalIp $internalIP `
            -externalSubnetName $externalSubnetName -internalSubnetName $internalSubnetName                  `
            -local $false
    }
}
function showMenu([ValidateNotNullOrEmpty()][string] $baseUrl, [ValidateNotNullOrEmpty()][string] $namespace, [bool] $isAzure) {
    $userinput = ""
    while ($userinput -ne "q") {
        Write-Host "================ $namespace menu version $version, common functions kube:$(GetCommonKubeVersion) ================"
        Write-Host "------ Install -------"
        Write-Host "1: Install $namespace"
        Write-Host "------ Status --------"
        Write-Host "2: Show status of $namespace"
        Write-Host "3: Show web site urls"
        Write-Host "4: Show $namespace passwords"
        Write-Host "5: Show $namespace detailed status"
        Write-Host "6: Show $namespace logs"
        Write-Host "7: Show urls to download client certificates"
        Write-Host "8: Show DNS entries for /etc/hosts"
        Write-Host "9: Troubleshoot Ingresses"        
        Write-Host "10: Restart $namespace"
        Write-Host "11: Show commands to SSH to $namespace containers"
        Write-Host "12: Delete all data in $namespace"        
        Write-Host "13: Show command to run Fabric.Realtime tester"        
        Write-Host "-----------"
        Write-Host "q: Go back to main menu"
        $userinput = Read-Host "Please make a selection"
        switch ($userinput) {
            '1' {
                InstallProduct -baseUrl $baseUrl -namespace $namespace -isAzure $isAzure
            } 
            '2' {
                kubectl get 'deployments,pods,services,ingress,secrets,persistentvolumeclaims,persistentvolumes,nodes' --namespace=$namespace -o wide
            } 
            '3' {
                if ($namespace -eq "fabricrealtime") {
                    $certhostname = $(ReadSecretValue certhostname $namespace)
                    Write-Host "Send HL7 to Mirth: server=${certhostname} port=6661"
                    Write-Host "Rabbitmq Queue: server=${certhostname} port=5671"
                    Write-Host "RabbitMq Mgmt UI is at: http://${certhostname}/rabbitmq/ user: admin password: $(ReadSecretPassword rabbitmqmgmtuipassword $namespace)"
                    Write-Host "Mirth Mgmt UI is at: http://${certhostname}/mirth/ user: admin password:admin"
                }
                elseif ($namespace -eq "fabricnlp") {
                    $loadBalancerIP = kubectl get svc traefik-ingress-service-public -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}' --ignore-not-found=true
                    $loadBalancerInternalIP = kubectl get svc traefik-ingress-service-internal -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}' --ignore-not-found=true
                    if ([string]::IsNullOrWhiteSpace($loadBalancerIP)) {
                        $loadBalancerIP = $loadBalancerInternalIP
                    }
                    $customerid = ReadSecretValue -secretname customerid
                    $customerid = $customerid.ToLower().Trim()
                                            
                    # Invoke-WebRequest -useb -Headers @{"Host" = "nlp.$customerid.healthcatalyst.net"} -Uri http://$loadBalancerIP/nlpweb | Select-Object -Expand Content
        
                    Write-Host "To test out the NLP services, open Git Bash and run:"
                    Write-Host "curl -L --verbose --header 'Host: solr.$customerid.healthcatalyst.net' 'http://$loadBalancerInternalIP/solr' -k" 
                    Write-Host "curl -L --verbose --header 'Host: $customerid.healthcatalyst.net' 'http://$loadBalancerInternalIP/external' -k" 
                    Write-Host "curl -L --verbose --header 'Host: nlp.$customerid.healthcatalyst.net' 'http://$loadBalancerIP/nlpweb' -k" 
                    Write-Host "curl -L --verbose --header 'Host: nlpjobs.$customerid.healthcatalyst.net' 'http://$loadBalancerIP/nlp' -k"
        
                    Write-Host "If you didn't setup DNS, add the following entries in your c:\windows\system32\drivers\etc\hosts file to access the urls from your browser"
                    Write-Host "$loadBalancerInternalIP solr.$customerid.healthcatalyst.net"            
                    Write-Host "$loadBalancerIP nlp.$customerid.healthcatalyst.net"            
                    Write-Host "$loadBalancerIP nlpjobs.$customerid.healthcatalyst.net"
                    Write-Host "$loadBalancerInternalIP $customerid.healthcatalyst.net"            
                    
                    # clear Google DNS cache: http://www.redsome.com/flush-clear-dns-cache-google-chrome-browser/
                    Write-Host "Launching http://$loadBalancerInternalIP/external in the web browser"
                    Start-Process -FilePath "http://$loadBalancerInternalIP/external";
                    Write-Host "Launching http://$loadBalancerInternalIP/solr in the web browser"
                    Start-Process -FilePath "http://$loadBalancerInternalIP/solr";
                    Write-Host "Launching http://$loadBalancerIP/nlpweb in the web browser"
                    Start-Process -FilePath "http://$loadBalancerIP/nlpweb";
                }
            } 
            '4' {
                if ($namespace -eq "fabricrealtime") {
                    $secrets = $(kubectl get secrets -n $namespace -o jsonpath="{.items[?(@.type=='Opaque')].metadata.name}")
                    Write-Host "All secrets in $namespace : $secrets"
                    WriteSecretPasswordToOutput -namespace $namespace -secretname "mysqlrootpassword"
                    WriteSecretPasswordToOutput -namespace $namespace -secretname "mysqlpassword"
                    WriteSecretValueToOutput  -namespace $namespace -secretname "certhostname"
                    WriteSecretPasswordToOutput -namespace $namespace -secretname "certpassword"
                    WriteSecretPasswordToOutput -namespace $namespace -secretname "rabbitmqmgmtuipassword"
                }
                elseif ($namespace -eq "fabricnlp") {
                    $secrets = $(kubectl get secrets -n $namespace -o jsonpath="{.items[?(@.type=='Opaque')].metadata.name}")
                    Write-Host "All secrets in $namespace : $secrets"
                    WriteSecretPasswordToOutput -namespace $namespace -secretname "mysqlrootpassword"
                    WriteSecretPasswordToOutput -namespace $namespace -secretname "mysqlpassword"
                    WriteSecretPasswordToOutput -namespace $namespace -secretname "smtprelaypassword"
                    WriteSecretValueToOutput  -namespace $namespace -secretname "jobserver-external-url"
                    WriteSecretValueToOutput  -namespace $namespace -secretname "nlpweb-external-url"
                }
            } 
            '5' {
                ShowStatusOfAllPodsInNameSpace "$namespace"
            } 
            '6' {
                ShowLogsOfAllPodsInNameSpace "$namespace"
            } 
            '7' {
                $certhostname = $(ReadSecretValue certhostname $namespace)
                $certpassword = $(ReadSecretPassword certpassword $namespace)
                $url = "http://${certhostname}/certificates/client/fabricrabbitmquser_client_cert.p12"
                Write-Host "Download the client certificate:"
                Write-Host "$url"
                Write-Host "Double-click and install in Local Machine. password: $certpassword"
                Write-Host "Open Certificate Management, right click on cert and give everyone access to key"
                
                $url = "http://${certhostname}/certificates/client/fabric_ca_cert.p12"
                Write-Host "Optional: Download the CA certificate:"
                Write-Host "$url"
                Write-Host "Double-click and install in Local Machine. password: $certpassword"            
            } 
            '8' {
                Write-Host "If you didn't setup DNS, add the following entries in your c:\windows\system32\drivers\etc\hosts file to access the urls from your browser"
                $loadBalancerIP = $(dig +short myip.opendns.com "@resolver1.opendns.com")
                $certhostname = $(ReadSecretValue certhostname $namespace)
                Write-Host "$loadBalancerIP $certhostname"            
            } 
            '9' {
                troubleshootIngress "$namespace"
            } 
            '10' {
                # this gets the new solr pods going before the old solr ones have released locks
                #                DeleteAllPodsInNamespace -namespace $namespace
                InstallProduct -baseUrl $baseUrl -namespace $namespace -isAzure $isAzure
            } 
            '11' {
                ShowSSHCommandsToContainers -namespace $namespace
            } 
            '12' {
                Write-Warning "This will delete all data in this namespace and clear out any secrets"
                Do { $confirmation = Read-Host "Do you want to continue? (y/n)"}
                while ([string]::IsNullOrWhiteSpace($confirmation))
            
                if ($confirmation -eq "y") {
                    DeleteNamespaceAndData -namespace "$namespace" -isAzure $isAzure
                }
            } 
            '13' {
                RunRealtimeTester -baseUrl $baseUrl
            } 
            'q' {
                return
            }
        }
        $userinput = Read-Host -Prompt "Press Enter to continue or q to go back to top menu"
        if ($userinput -eq "q") {
            return
        }
        [Console]::ResetColor()
        Clear-Host
    }        
}

Write-Information -MessageData "end product-menu.ps1 version $versionmenucommon"