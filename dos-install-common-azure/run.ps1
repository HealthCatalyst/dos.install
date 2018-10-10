$PSVersionTable

Import-Module PackageManagement
# Find-Package Pester

# Install-Module Pester -Force

Remove-Module "dos-install-common-azure"
Import-Module "$PSScriptRoot\dos-install-common-azure.psd1"

Write-Host "Loaded module"

# Install-Module -Name AzureRM -AllowClobber