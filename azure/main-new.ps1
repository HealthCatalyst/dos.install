param([bool]$prerelease, [bool]$local)
$version = "2018.10.12.04"
[Console]::ResetColor()
Write-Host "--- main-new.ps1 version $version ---"
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

Import-Module PowerShellGet

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$topLevelFolder = "$here\..\..\"
$module = "DosInstallUtilities.Kube"
Get-Module "$module" | Remove-Module -Force
if ($local) {
    Import-Module "$topLevelFolder\$module\$module.psm1" -Force
}
else {
    Install-Module -Name $module -Force -AllowClobber
}

$module = "DosInstallUtilities.Azure"
Get-Module "$module" | Remove-Module -Force
if ($local) {

    Import-Module "$topLevelFolder\$module\$module.psm1" -Force
}
else {
    Install-Module -Name $module -Force -AllowClobber
}

$module = "DosInstallUtilities.Menu"
Get-Module "$module" | Remove-Module -Force
if ($local) {

    Import-Module "$topLevelFolder\$module\$module.psm1" -Force
}
else {
    Install-Module -Name $module -Force -AllowClobber
}

ShowMainMenu -baseUrl $GITHUB_URL -local $local
