param([ValidateNotNullOrEmpty()][string]$baseUrl, [string]$prerelease)
$version = "2018.11.01.06"
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

Write-Host "Importing PowershellGet module"
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
                    Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Force -Scope CurrentUser
                    Import-Module -Name $module
                }
            }
        }
        else {
            Write-Host "Module $module does not exist.  Installing it..."
            Install-Module -Name $module -MinimumVersion $minVersion -AllowClobber -Scope CurrentUser
            Import-Module -Name $module
        }
    }
}

InstallOrUpdateModule -module "DosInstallUtilities.Kube" -local $local -minVersion "1.86"

InstallOrUpdateModule -module "DosInstallUtilities.OnPrem" -local $local -minVersion "1.99"

InstallOrUpdateModule -module "DosInstallUtilities.Realtime" -local $local -minVersion "1.83"

# show Information messages
$InformationPreference = "Continue"

ShowOnPremMenu -baseUrl $baseUrl -local $local -isPrerelease $isPrerelease