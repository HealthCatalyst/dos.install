$naPath = 'C:\Catalyst\git\dos.install\dos-install-common-azure'
Set-Location $naPath

Import-Module Pester

Invoke-Pester "$naPath\Module.Tests.ps1"
Invoke-Pester "$naPath\function-SetStorageAccountNameIntoSecret.Tests.ps1"