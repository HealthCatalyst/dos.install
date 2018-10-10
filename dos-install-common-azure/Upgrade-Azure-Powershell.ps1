. $PSScriptRoot\functions\Uninstall-AllModules.ps1

Uninstall-AllModules -TargetModule AzureRM -Version 5.7.0 -Force

Get-Module PowerShellGet
Install-Module PowerShellGet -Force

# restart powershell session

Install-Module -Name AzureRM -AllowClobber

# Install-Module -Name AzureRM.Aks -AllowPrerelease
Install-Module -Name AzureRM.Aks.Netcore
