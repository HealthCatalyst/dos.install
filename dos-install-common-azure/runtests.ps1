$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set-Location $naPath

$ErrorActionPreference = "Stop"

Import-Module Pester

$VerbosePreference = "continue"

$module = "dos-install-common-azure"
Get-Module "$module" | Remove-Module -Force

Import-Module "$here\$module.psm1" -Force

$module = Get-Module -Name $module
$module
$module | Select-Object *

$module = "dos-install-common-kube"
Get-Module "$module" | Remove-Module -Force

Import-Module "$here\..\$module\$module.psm1" -Force

$module = Get-Module -Name $module
$module
$module | Select-Object *



Invoke-Pester "$here\Module.Tests.ps1"

# Storage
# Invoke-Pester "$here\functions\Storage\GetStorageAccountName.Tests.ps1"
# Invoke-Pester "$here\functions\Storage\SetStorageAccountNameIntoSecret.Tests.ps1" -Tag 'Unit'
# Invoke-Pester "$here\functions\Storage\SetStorageAccountNameIntoSecret.Tests.ps1" -Tag 'Integration'

# # Subscription
# Invoke-Pester "$here\functions\Subscription\SetCurrentAzureSubscription.Tests.ps1" -Tag 'Unit'
# Invoke-Pester "$here\functions\Subscription\SetCurrentAzureSubscription.Tests.ps1" -Tag 'Integration'

# Load Balancer
# Subscription
Invoke-Pester "$here\functions\LoadBalancer\SetupLoadBalancer.Tests.ps1" -Tag 'Unit'
Invoke-Pester "$here\functions\LoadBalancer\SetupLoadBalancer.Tests.ps1" -Tag 'Integration'
