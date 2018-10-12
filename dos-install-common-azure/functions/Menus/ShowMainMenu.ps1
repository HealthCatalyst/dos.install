<#
.SYNOPSIS
ShowMainMenu

.DESCRIPTION
ShowMainMenu

.INPUTS
ShowMainMenu - The name of ShowMainMenu

.OUTPUTS
None

.EXAMPLE
ShowMainMenu

.EXAMPLE
ShowMainMenu


#>
function ShowMainMenu() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $baseUrl
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $local
    )

    Write-Verbose 'ShowMainMenu: Starting'

    $userinput = ""
    while ($userinput -ne "q") {
        $skip = $false
        $currentcluster = ""
        if (Test-CommandExists kubectl) {
            $currentcluster = $(kubectl config current-context 2> $null)
        }

        Write-Host "================ Health Catalyst ================"
        if ($prerelease) {
            Write-Host "prerelease flag: $prerelease"
        }
        Write-Warning "CURRENT CLUSTER: $currentcluster"

        Write-Host "------ Infrastructure -------"
        Write-Host "1: Configure existing Azure Container Service"
        Write-Host "2: Launch Kubernetes Dashboard"
        Write-Host "------ Troubleshooting Infrastructure -------"
        Write-Host "3: Start VMs in Resource Group"
        Write-Host "4: Stop VMs in Resource Group"

        #    Write-Host "3: Launch Traefik Dashboard"
        Write-Host "9: Show nodes"
        Write-Host "10: Show DNS entries for /etc/hosts"

        Write-Host "----- Troubleshooting ----"
        Write-Host "20: Show status of cluster"
        Write-Host "22: Show SSH commands to VMs"
        Write-Host "23: View status of DNS pods"
        Write-Host "24: Restart all VMs"

        Write-Host "------ Keyvault -------"
        Write-Host "26: Copy Kubernetes secrets to keyvault"
        Write-Host "27: Copy secrets from keyvault to kubernetes"

        Write-Host "------ Load Balancer -------"
        Write-Host "30: Test load balancer"
        Write-Host "31: Fix load balancers"
        Write-Host "32: Redeploy load balancers"
        Write-Host "33: Launch Load Balancer Dashboard"

        Write-Host "------- Troubleshooting ----"
        Write-Host "50: Troubleshooting Menu"

        Write-Host "------ Realtime -------"
        Write-Host "52: Fabric.Realtime Menu"

        Write-Host "------ Older Scripts -------"
        Write-Host "100: Go to old menu"

        Write-Host "q: Quit"
        #--------------------------------------
        $userinput = Read-Host "Please make a selection"
        switch ($userinput) {
            '1' {
                $config = $(ReadConfigFile).Config
                Write-Verbose $config

                LoginToAzure

                SetCurrentAzureSubscription -subscriptionName $($config.azure.subscription)

                SetStorageAccountNameIntoSecret -resourceGroup $config.azure.resourceGroup -customerid $config.customerid

                kubectl get "deployments,pods,services,ingress,secrets" --namespace="default" -o wide
                kubectl get "deployments,pods,services,ingress,secrets" --namespace=kube-system -o wide

                InitHelm

                SetupNetworkSecurity -config $config
                SetupLoadBalancer -baseUrl $baseUrl -config $config -local $local
            }
            '2' {
                LaunchKubernetesDashboard
            }
            '3' {
                Do {
                    $AKS_PERS_RESOURCE_GROUP = Read-Host "Resource Group"
                }
                while ([string]::IsNullOrWhiteSpace($AKS_PERS_RESOURCE_GROUP))

                StartVMsInResourceGroup -resourceGroup $AKS_PERS_RESOURCE_GROUP
            }
            '4' {
                Do {
                    $AKS_PERS_RESOURCE_GROUP = Read-Host "Resource Group"
                }
                while ([string]::IsNullOrWhiteSpace($AKS_PERS_RESOURCE_GROUP))
                StopVMsInResourceGroup -resourceGroup $AKS_PERS_RESOURCE_GROUP
            }
            '9' {
                Write-Host "Current cluster: $(kubectl config current-context)"
                kubectl version --short
                kubectl get "nodes"
            }
            '10' {
                Write-Host "If you didn't setup DNS, add the following entries in your c:\windows\system32\drivers\etc\hosts file to access the urls from your browser"
                $loadBalancerIPResult = GetLoadBalancerIPs
                $EXTERNAL_IP = $loadBalancerIPResult.ExternalIP

                $dnshostname = $(ReadSecretValue -secretname "dnshostname" -namespace "default")
                Write-Host "$EXTERNAL_IP $dnshostname"
            }
            '20' {
                Write-Host "Current cluster: $(kubectl config current-context)"
                kubectl version --short
                kubectl get "deployments,pods,services,ingress,secrets,nodes" --namespace=kube-system -o wide
            }
            '22' {
                ShowSSHCommandsToVMs
            }
            '23' {
                RestartDNSPodsIfNeeded
            }
            '24' {
                RestartAzureVMsInResourceGroup
            }
            '26' {
                $currentResourceGroup = ReadSecretData -secretname azure-secret -valueName resourcegroup -Verbose
                CopyKubernetesSecretsToKeyVault -resourceGroup $currentResourceGroup -Verbose
            }
            '27' {
                $currentResourceGroup = ReadSecretData -secretname azure-secret -valueName resourcegroup -Verbose
                CopyKeyVaultSecretsToKubernetes -resourceGroup $currentResourceGroup -Verbose
            }
            '30' {
                TestAzureLoadBalancer
            }
            '31' {
                $DEFAULT_RESOURCE_GROUP = ReadSecretData -secretname azure-secret -valueName resourcegroup

                if ([string]::IsNullOrWhiteSpace($AKS_PERS_RESOURCE_GROUP)) {
                    Do {
                        $AKS_PERS_RESOURCE_GROUP = Read-Host "Resource Group: (default: $DEFAULT_RESOURCE_GROUP)"
                        if ([string]::IsNullOrWhiteSpace($AKS_PERS_RESOURCE_GROUP)) {
                            $AKS_PERS_RESOURCE_GROUP = $DEFAULT_RESOURCE_GROUP
                        }
                    }
                    while ([string]::IsNullOrWhiteSpace($AKS_PERS_RESOURCE_GROUP))
                }
                FixLoadBalancers -resourceGroup $AKS_PERS_RESOURCE_GROUP
            }
            '32' {
                $config = $(ReadConfigFile).Config
                Write-Host $config

                $local = $false
                SetupLoadBalancer -baseUrl $baseUrl -config $config -local $local
            }
            '33' {
                $loadBalancerInfo = $(GetLoadBalancerIPs)
                $loadBalancerInternalIP = $loadBalancerInfo.InternalIP
                LaunchTraefikDashboard -internalIp $loadBalancerInternalIP
            }
            '50' {
                ShowTroubleshootingMenu -baseUrl $baseUrl -local $local
                $skip = $true
            }
            '52' {
                ShowProductMenu -baseUrl $baseUrl -namespace "fabricrealtime" -local $local
                $skip = $true
            }
            '100' {
                # curl -useb https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/azure/main.ps1 | iex;
                # $Script = Invoke-WebRequest -useb ${GITHUB_URL}/azure/main.ps1?f=$randomstring;
                # $ScriptBlock = [Scriptblock]::Create($Script.Content)
                # Invoke-Command -ScriptBlock $ScriptBlock
                $scriptPath = "curl -useb https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/azure/main.ps1 | iex;"
                # $argumentList = ""
                # Invoke-Expression "$scriptPath $argumentList"
                # Invoke-Expression 'cmd /c start powershell -Command { $scriptPath $argumentList }'
                # Start-Process powershell -Command "$scriptPath"
                start-process powershell.exe -argument "-noexit -nologo -command $scriptPath"
                exit 0
            }
            'q' {
                return
            }
        }
        if (!($skip)) {
            $userinput = Read-Host -Prompt "Press Enter to continue or q to exit"
            if ($userinput -eq "q") {
                return
            }
        }
        [Console]::ResetColor()
        Clear-Host
    }

    Write-Verbose 'ShowMainMenu: Done'
}

Export-ModuleMember -Function 'ShowMainMenu'