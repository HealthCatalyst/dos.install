param([string]$branch, [bool]$local)
$version = "2018.10.18.03"
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
$minVersion = "6.10.0"
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
        }
    }
}
else {
    Write-Host "Module $module does not exist"
    Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Scope CurrentUser
}

Import-Module PowerShellGet -Force

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

if($local){
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
                    Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Force -Scope CurrentUser
                }
            }
        }
        else {
            Write-Host "Module $module does not exist"
            Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Scope CurrentUser
        }
    }
}

# Set-StrictMode -Off
# $global:options = @{CustomArgumentCompleters = @{};NativeArgumentCompleters = @{}}
# InstallOrUpdateModule -module "RabbitMQTools" -local $false -minVersion "1.5"
# Set-StrictMode -Version latest

# InstallOrUpdateModule -module "PSRabbitMq" -local $false -minVersion "0.3.1"

InstallOrUpdateModule -module "DosInstallUtilities.Kube" -local $local -minVersion "1.7"

InstallOrUpdateModule -module "DosInstallUtilities.Azure" -local $local -minVersion "1.6"

InstallOrUpdateModule -module "DosInstallUtilities.Menu" -local $local -minVersion "1.6"

InstallOrUpdateModule -module "DosInstallUtilities.Realtime" -local $local -minVersion "1.6"

ShowMainMenu -baseUrl $GITHUB_URL -local $local
