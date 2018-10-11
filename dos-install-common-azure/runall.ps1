$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Set-StrictMode -Version Latest

# Set-Location $naPath

$ErrorActionPreference = "Stop"

$VerbosePreference = "continue"

$module = "dos-install-common-azure"
Get-Module "$module" | Remove-Module -Force

Import-Module "$here\$module.psm1" -Force

$module = "dos-install-common-kube"
Get-Module "$module" | Remove-Module -Force

Import-Module "$here\..\$module\$module.psm1" -Force

$configfilepath = "$here\..\deployments\hcut-acs-rg.json"
$config = $(Get-Content $configfilepath -Raw | ConvertFrom-Json)
Write-Verbose $config

$GITHUB_URL = "."
$local = $true

LoginToAzure

SetCurrentAzureSubscription -subscriptionName $($config.azure.subscription)

SetStorageAccountNameIntoSecret -resourceGroup $config.azure.resourceGroup -customerid $config.customerid

kubectl get "deployments,pods,services,ingress,secrets" --namespace="default" -o wide
kubectl get "deployments,pods,services,ingress,secrets" --namespace=kube-system -o wide

InitHelm

SetupNetworkSecurity -config $config
SetupLoadBalancer -baseUrl $GITHUB_URL -config $config -local $local

LaunchKubernetesDashboard
