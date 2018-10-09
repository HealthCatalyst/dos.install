$module = Get-Module -Name "dos-install-common-kube"
$module | Select-Object *

$params = @{
    'Author' = 'Health Catalyst'
    'CompanyName' = 'Health Catalyst'
    'Description' = 'Functions to configure Kubernetes'
    'NestedModules' = 'dos-install-common-kube'
    'Path' = ".\dos-install-common-kube.psd1"
}

New-ModuleManifest @params
