$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Set-StrictMode -Version Latest

# Set-Location $naPath

$ErrorActionPreference = "Stop"

Import-Module Pester

$VerbosePreference = "continue"

$module = "dos-install-common-azure"
Get-Module "$module" | Remove-Module -Force

Import-Module "$here\$module.psm1" -Force

# $module = Get-Module -Name $module
# $module
# $module | Select-Object *

$module = "dos-install-common-kube"
Get-Module "$module" | Remove-Module -Force

Import-Module "$here\..\$module\$module.psm1" -Force

# $module = Get-Module -Name $module
# $module
# $module | Select-Object *



Invoke-Pester "$here\Module.Tests.ps1"

# Storage
# Invoke-Pester "$here\functions\Storage\GetStorageAccountName.Tests.ps1"
Invoke-Pester "$here\functions\Storage\SetStorageAccountNameIntoSecret.Tests.ps1" -Tag 'Unit'
# Invoke-Pester "$here\functions\Storage\SetStorageAccountNameIntoSecret.Tests.ps1" -Tag 'Integration'

# # Subscription
# Invoke-Pester "$here\functions\Subscription\SetCurrentAzureSubscription.Tests.ps1" -Tag 'Unit'
# Invoke-Pester "$here\functions\Subscription\SetCurrentAzureSubscription.Tests.ps1" -Tag 'Integration'

# Network
 # Invoke-Pester "$here\functions\Network\SetupNetworkSecurity.Tests.ps1" -Tag 'Integration' -Verbose


# Load Balancer
# Invoke-Pester "$here\functions\LoadBalancer\SetupLoadBalancer.Tests.ps1" -Tag 'Unit'
Invoke-Pester "$here\functions\LoadBalancer\SetupLoadBalancer.Tests.ps1" -Tag 'Integration' -Verbose

# arm
# Invoke-Pester "$here\functions\arm\CreateServicePrincipal.Tests.ps1" -Tag 'Integration' -Verbose

# Invoke-Pester "$here\functions\arm\AssignPermissionsToServicePrincipal.Tests.ps1" -Tag 'Integration' -Verbose

# Invoke-Pester "$here\functions\arm\CleanResourceGroup.Tests.ps1" -Tag 'Cluster' -Verbose

# Invoke-Pester "$here\functions\arm\DeployTemplate.Tests.ps1" -Tag 'Unit' -Verbose
# Invoke-Pester "$here\functions\arm\DeployTemplate.Tests.ps1" -Tag 'Cluster' -Verbose
# Invoke-Pester "$here\functions\arm\DeployTemplate.Tests.ps1" -Tag 'ACS' -Verbose
# Invoke-Pester "$here\functions\arm\DeployTemplate.Tests.ps1" -Tag 'AKS' -Verbose

# Set-AzureRmContext -SubscriptionId "c8b1589f-9270-46ee-967a-417817e7d10d" -Verbose
# Get-AzureRmAks

# $resourceGroup="fabrickubernetes2"
# $name="Kluster-$resourceGroup"

# Import-AzureRmAksCredential -ResourceGroupName "$resourceGroup" -Name $name -Force

# Start-AzureRmAksDashboard -ResourceGroupName "$resourceGroup" -Name $name -Verbose
