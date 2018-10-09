$naPath = 'C:\Catalyst\git\dos.install\dos-install-common-azure'
Set-Location $naPath

$VerbosePreference = "continue"
$ErrorActionPreference = "Stop"

Import-Module Pester

Invoke-Pester "$naPath\Module.Tests.ps1"
Invoke-Pester "$naPath\functions\function-GetStorageAccountName.Tests.ps1"
Invoke-Pester "$naPath\functions\function-SetStorageAccountNameIntoSecret.Tests.ps1"
