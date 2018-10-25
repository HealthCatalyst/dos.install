param([ValidateNotNullOrEmpty()][string]$baseUrl, [string]$prerelease)
$version = "2018.10.24.02"
Write-Host "--- onprem-menu.ps1 version $version ---"
Write-Host "baseUrl = $baseUrl"
Write-Host "prerelease flag: $prerelease"

# http://www.rlmueller.net/PSGotchas.htm
# Trap {"Error: $_"; Break;}
Set-StrictMode -Version latest

[bool] $local = $false

# stop whenever there is an error
# $ErrorActionPreference = "Stop"
# show Information messages
$InformationPreference = "Continue"

if("$prerelease" -eq "yes"){
    $isPrerelease = $true
    Write-Host "prerelease: yes"
}
else{
    $isPrerelease = $false
}

[string] $set = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
[string] $randomstring = ""
$randomstring += $set | Get-Random

Write-Host "Powershell version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"

mkdir -p ${HOME}

Import-Module PowerShellGet -Force

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

function InstallOrUpdateModule() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $module
        ,
        [Parameter(Mandatory = $true)]
        [bool]
        $local
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $minVersion
    )

    if ($local) {
        Get-Module -Name "$module" | Remove-Module -Force
        Import-Module "$topLevelFolder\$module\$module.psm1" -Force
    }
    else {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Host "Module $module exists"

            Import-Module -Name $module
            $moduleInfo = $(Get-Module -Name "$module")
            if ($null -eq $moduleInfo) {
                Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Scope CurrentUser
            }
            else {
                Write-Host "Checking Version of $module module is $minVersion"
                if ($minVersion -ne $moduleInfo.Version.ToString()) {
                    Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Force -Scope CurrentUser
                    Import-Module -Name $module
                }
            }
        }
        else {
            Write-Host "Module $module does not exist"
            Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Scope CurrentUser
            Import-Module -Name $module
        }
    }
}

InstallOrUpdateModule -module "DosInstallUtilities.OnPrem" -local $local -minVersion "1.1"

# show Information messages
$InformationPreference = "Continue"

$userinput = ""
while ($userinput -ne "q") {
    $skip=$false
    Write-Host "================ Health Catalyst version $version ================"
    Write-Host "------ On-Premise -------"
    Write-Host "1: Setup Master VM"
    Write-Host "2: Show command to join another node to this cluster"
    Write-Host "3: Uninstall Docker and Kubernetes"
    Write-Host "4: Show all nodes"
    Write-Host "5: Show status of cluster"
    Write-Host "-----------"
    Write-Host "20: Troubleshooting Menu"
    Write-Host "-----------"
    Write-Host "51: Fabric NLP Menu"
    Write-Host "-----------"
    Write-Host "52: Fabric Realtime Menu"
    Write-Host "q: Quit"
    $userinput = Read-Host "Please make a selection"
    switch ($userinput) {
        '1' {
            SetupMaster -baseUrl $baseUrl -singlenode $false
        }
        '2' {
            ShowCommandToJoinCluster -baseUrl $baseUrl -prerelease $isPrerelease
        }
        '3' {
            UninstallDockerAndKubernetes
        }
        '4' {
            ShowNodes
        }
        '5' {
            ShowStatusOfCluster
        }
        '20' {
            showTroubleshootingMenu -baseUrl $baseUrl -isAzure $false
            $skip=$true
        }
        '51' {
            showMenu -baseUrl $baseUrl -namespace "fabricnlp" -isAzure $false
            $skip=$true
        }
        '52' {
            showMenu -baseUrl $baseUrl -namespace "fabricrealtime" -isAzure $false
            $skip=$true
        }
        'q' {
            return
        }
    }
    if(!($skip)){
        $userinput = Read-Host -Prompt "Press Enter to continue or q to exit"
        if($userinput -eq "q"){
            return
        }
    }
    [Console]::ResetColor()
    Clear-Host
}
