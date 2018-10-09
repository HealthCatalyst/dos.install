$naPath = 'C:\Catalyst\git\dos.install\dos-install-common-azure'
Set-Location $naPath

$VerbosePreference = "continue"
$ErrorActionPreference = "Stop"

Import-Module Pester

Invoke-Pester "$naPath\Module.Tests.ps1"

# Storage
Invoke-Pester "$naPath\functions\Storage\GetStorageAccountName.Tests.ps1"
Invoke-Pester "$naPath\functions\Storage\SetStorageAccountNameIntoSecret.Tests.ps1"
