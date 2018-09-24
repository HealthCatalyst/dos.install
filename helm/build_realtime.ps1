# builds the release
# based on: https://medium.com/containerum/how-to-make-and-share-your-own-helm-package-50ae40f6c221

# specification for charts: https://docs.helm.sh/developing_charts

Write-Host "Remove existing tar"
Remove-Item -Path "dos.realtime-*.tgz"

Write-Host "Packaging realtime"
helm package dos.realtime

Write-Host "moving realtime-*.tgz tp releases/"
Move-Item dos.realtime-*.tgz releases/ -Force

Write-Host "Updating index"
helm repo index releases/ --url https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/helm/releases/

Write-Host "Remove existing tar"
Remove-Item -Path "dos.realtime-*.tgz" -Force

Write-Host "--------------------------------------------------"
Write-Host "After you commit this change, the chart will be ready to serve"
Write-Host "You can add it to a local helm by: helm repo add realtime https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/helm/releases"

Write-Host "And install realtime via: helm install releases/realtime --name=realtime"
Write-Host "--------------------------------------------------"
