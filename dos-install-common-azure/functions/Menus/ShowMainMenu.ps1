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
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $baseUrl
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
        #    Write-Host "3: Launch Traefik Dashboard"

        Write-Host "------ Keyvault -------"
        Write-Host "26: Copy Kubernetes secrets to keyvault"
        Write-Host "27: Copy secrets from keyvault to kubernetes"

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
                LaunchTraefikDashboard
            }
            '26' {
                $currentResourceGroup = ReadSecretData -secretname azure-secret -valueName resourcegroup -Verbose
                CopyKubernetesSecretsToKeyVault -resourceGroup $currentResourceGroup -Verbose
            }
            '27' {
                $currentResourceGroup = ReadSecretData -secretname azure-secret -valueName resourcegroup -Verbose
                CopyKeyVaultSecretsToKubernetes -resourceGroup $currentResourceGroup -Verbose
            }
            '52' {
                ShowProductMenu -baseUrl $baseUrl -namespace "fabricrealtime"
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