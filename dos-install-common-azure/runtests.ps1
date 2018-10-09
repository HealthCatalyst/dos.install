$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set-Location $naPath

$ErrorActionPreference = "Stop"

Import-Module Pester

$VerbosePreference = "continue"

$module = "dos-install-common-azure"
Get-Module "$module" | Remove-Module -Force

Import-Module "$here\$module.psm1" -Force

$module = Get-Module -Name "dos-install-common-azure"
$module
$module | Select-Object *

Invoke-Pester "$here\Module.Tests.ps1"

# Storage
Invoke-Pester "$here\functions\Storage\GetStorageAccountName.Tests.ps1"
Invoke-Pester "$here\functions\Storage\SetStorageAccountNameIntoSecret.Tests.ps1"
