$module = Get-Module -Name "dos-install-common-azure"
$module | Select-Object *

$params = @{
    'Author' = 'Health Catalyst'
    'CompanyName' = 'Health Catalyst'
    'Description' = 'Functions to configure Azure'
    'NestedModules' = 'dos-install-common-azure'
    'Path' = ".\dos-install-common-azure.psd1"
}

New-ModuleManifest @params
