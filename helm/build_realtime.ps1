# builds the release
# based on: https://medium.com/containerum/how-to-make-and-share-your-own-helm-package-50ae40f6c221

# specification for charts: https://docs.helm.sh/developing_charts

Write-Host "Running lint"
helm lint fabricrealtime

Write-Host "Remove existing tar"
Remove-Item -Path "fabricrealtime-*.tgz"

Write-Host "Packaging realtime"
helm package fabricrealtime

Write-Host "moving fabricrealtime-*.tgz tp releases/"
Move-Item fabricrealtime-*.tgz releases/ -Force

Write-Host "Updating index"
helm repo index releases/ --url https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/helm/releases/

Write-Host "Remove existing tar"
Remove-Item -Path "fabricrealtime-*.tgz" -Force

Write-Host "--------------------------------------------------"
Write-Host "After you commit this change, the chart will be ready to serve"
Write-Host "You can add it to a local helm by: helm repo add dos https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/helm/releases"
Write-Host "If you already have it, run this to update the list: helm repo update"

Write-Host "And install realtime via: helm install -f myvalues.yaml dos/fabricrealtime --name=fabricrealtime --namespace fabricrealtime --verify --wait"
Write-Host "To uninstall a release: helm del --purge realtime"
Write-Host "--------------------------------------------------"
