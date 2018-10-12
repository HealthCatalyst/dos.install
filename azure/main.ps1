param([bool]$prerelease, [bool]$local)
$version = "2018.10.12.06"
[Console]::ResetColor()
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

Write-Host "Powershell version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Build)"

Import-Module PowerShellGet -Force
Import-Module AzureRM -Force

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$topLevelFolder = "$here\..\..\"
$module = "DosInstallUtilities.Kube"
if ($local) {
    Get-Module -Name "$module" | Remove-Module -Force
    Import-Module "$topLevelFolder\$module\$module.psm1" -Force
}
else {
    $minVersion = "1.3"
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host "Module $module exists"

        Import-Module -Name $module
        $moduleInfo = $(Get-Module -Name "$module")
        if ($null -eq $moduleInfo) {
            Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber
        }
        else {
            Write-Host "Checking Version of $module module is $minVersion"
            if ($minVersion -ne $moduleInfo.Version.ToString()) {
                Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber
            }
        }
    }
    else {
        Write-Host "Module $module does not exist"
        Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber
    }
}

$module = "DosInstallUtilities.Azure"
if ($local) {
    Get-Module -Name "$module" | Remove-Module -Force
    Import-Module "$topLevelFolder\$module\$module.psm1" -Force
}
else {
    $minVersion = "1.3"
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host "Module $module exists"

        Import-Module -Name $module
        $moduleInfo = $(Get-Module -Name "$module")
        if ($null -eq $moduleInfo) {
            Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber
        }
        else {
            Write-Host "Checking Version of $module module is $minVersion"
            if ($minVersion -ne $moduleInfo.Version.ToString()) {
                Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber
            }
        }
    }
    else {
        Write-Host "Module $module does not exist"
        Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber
    }
}

$module = "DosInstallUtilities.Menu"
if ($local) {
    Get-Module -Name "$module" | Remove-Module -Force
    Import-Module "$topLevelFolder\$module\$module.psm1" -Force
}
else {
    $minVersion = "1.0"
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host "Module $module exists"
        Import-Module -Name $module
        $moduleInfo = $(Get-Module -Name "$module")
        if ($null -eq $moduleInfo) {
            Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber
        }
        else {
            Write-Host "Checking Version of $module module is $minVersion"
            if ($minVersion -ne $moduleInfo.Version.ToString()) {
                Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber
            }
        }
    }
    else {
        Write-Host "Module $module does not exist"
        Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber
    }
}

ShowMainMenu -baseUrl $GITHUB_URL -local $local
