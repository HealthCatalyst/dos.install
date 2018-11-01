param([string]$branch, [bool]$local)
$version = "2018.10.29.06"
[Console]::ResetColor()
Write-Host "--- main.ps1 version $version ---"
Write-Host "branch: $branch"

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
#   curl -useb https://raw.githubusercontent.com/HealthCatalyst/dos.install/release/azure/main.ps1 | iex;
#   curl -useb https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/azure/main.ps1 | iex;
#   curl -sSL  https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/azure/main.ps1 | pwsh -Interactive -NoExit -c -;

if ($local) {
    $GITHUB_URL = "."
}
elseif ($branch) {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/$branch"
}
else {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/release"
}
Write-Host "GITHUB_URL: $GITHUB_URL"

Write-Host "Powershell version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Build)"

$module = "AzureRM"
$minVersion = "6.11.0"
Write-Host "Checking Module $module with minVersion=$minVersion"
if (Get-Module -ListAvailable -Name $module) {
    Write-Host "Module $module exists"

    Import-Module -Name $module
    $moduleInfo = $(Get-Module -Name "$module")
    if ($null -eq $moduleInfo) {
        Write-Host "Could not get info on $module so installing it..."
        Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Scope CurrentUser
    }
    else {
        Write-Host "Checking Version of $module module is $minVersion"
        [string] $currentVersion = $moduleInfo.Version.ToString()
        if ($minVersion -ne $currentVersion) {
            Write-Host "Version of $module is $currentVersion while we expected $minVersion.  Installing version $minVersion..."
            Update-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Force -Scope CurrentUser
            Import-Module -Name $module
        }
    }
}
else {
    Write-Host "Module $module does not exist.  Installing it..."
    Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Scope CurrentUser
    Import-Module -Name $module
}

Import-Module PowerShellGet -Force

$repo = $(Get-PSRepository -Name "PSGallery")

if ($repo) {
    if ( $repo.InstallationPolicy -ne "Trusted") {
        Write-Host "Setting PSGallery to be trusted"
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    }
}
else {
    Write-Host "Setting PSGallery to be trusted"
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

}

if ($local) {
    [string] $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    [string] $topLevelFolder = "$here\..\..\"
}

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
                    Write-Host "Installing Version of $module = $minVersion"
                    Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Force -Scope CurrentUser
                    Write-Host "Importing $module"
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

# Set-StrictMode -Off
# $global:options = @{CustomArgumentCompleters = @{};NativeArgumentCompleters = @{}}
# InstallOrUpdateModule -module "RabbitMQTools" -local $false -minVersion "1.5"
# Set-StrictMode -Version latest

# InstallOrUpdateModule -module "PSRabbitMq" -local $false -minVersion "0.3.1"

InstallOrUpdateModule -module "DosInstallUtilities.Kube" -local $local -minVersion "1.80"

InstallOrUpdateModule -module "DosInstallUtilities.Azure" -local $local -minVersion "1.82"

InstallOrUpdateModule -module "DosInstallUtilities.Menu" -local $local -minVersion "1.81"

InstallOrUpdateModule -module "DosInstallUtilities.Realtime" -local $local -minVersion "1.80"

ShowMainMenu -baseUrl $GITHUB_URL -local $local
