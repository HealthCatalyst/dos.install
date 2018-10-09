Remove-Module "dos-install-common-azure"
Import-Module "$PSScriptRoot\dos-install-common-azure.psd1"

$module = Get-Module -Name "dos-install-common-azure"
$module
$module | Select-Object *

Write-Host "Loaded module"