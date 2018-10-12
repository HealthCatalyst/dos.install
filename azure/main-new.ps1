param([bool]$prerelease, [bool]$local)
$version = "2018.06.06.01"
Write-Host "--- main.ps1 version $version ---"
Write-Host "prerelease flag: $prerelease"

# http://www.rlmueller.net/PSGotchas.htm
# Trap {"Error: $_"; Break;}
# Set-StrictMode -Version latest

if ($local) {
    Write-Host "use local files: $local"
}

# https://stackoverflow.com/questions/9948517/how-to-stop-a-powershell-script-on-the-first-error
Set-StrictMode -Version latest

# stop whenever there is an error
$ErrorActionPreference = "Stop"
# show Information messages
$InformationPreference = "Continue"

# This script is meant for quick & easy install via:
#   curl -useb https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/azure/main.ps1 | iex;
#   curl -sSL  https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/azure/main.ps1 | pwsh -Interactive -NoExit -c -;

if ($prerelease) {
    if ($local) {
        $GITHUB_URL = "."
    }
    else {
        $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/master"
    }
}
else {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/release"
}
Write-Host "GITHUB_URL: $GITHUB_URL"

$set = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
[string] $randomstring += $set | Get-Random

Write-Host "Powershell version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Build)"

if ($local) {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    $module = "dos-install-common-azure"
    Get-Module "$module" | Remove-Module -Force
    Import-Module "$here\..\$module\$module.psm1" -Force
}
else {
    Install-Module -Name dos-install-common-kube
}

if ($local) {
    $module = "dos-install-common-kube"
    Get-Module "$module" | Remove-Module -Force
    Import-Module "$here\..\$module\$module.psm1" -Force
}
else {
    Install-Module -Name dos-install-common-azure
}

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
            SetupLoadBalancer -baseUrl $GITHUB_URL -config $config -local $local
        }
        '2' {
            LaunchKubernetesDashboard
            LaunchTraefikDashboard
        }
        '3' {
            LaunchTraefikDashboard
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
