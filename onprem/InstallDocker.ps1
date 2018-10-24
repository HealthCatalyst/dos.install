
# upgrade powershell
# https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6

$PSVersionTable.PSVersion

# curl -OutFile powershell5.msu http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu

# https://docs.microsoft.com/en-us/powershell/wmf/5.1/install-configure

# https://docs.docker.com/install/windows/docker-ee/

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# https://github.com/OneGet/MicrosoftDockerProvider
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
# Uninstall-Package -ProviderName DockerMsftProvider -Name Docker -Verbose
# 17.06.01 is minimum
Install-Package -Name Docker -ProviderName DockerMsftProvider -Force -RequiredVersion 18.03.1-ee-3
Restart-Computer -Force

Start-Service docker

# & $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchDaemon

# https://docs.docker.com/docker-for-windows/faqs/#why-does-docker-for-windows-sometimes-lose-network-connectivity-causing-push-or-pull-commands-to-fail

# https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon

Uninstall-Package -Name docker -ProviderName DockerMsftProvider
Uninstall-Module -Name DockerMsftProvider

# https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon

# install google chrome
$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor =  "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

# download docker from: https://docs.docker.com/docker-for-windows/release-notes/

curl -OutFile dockerinstaller.exe https://download.docker.com/win/stable/19507/Docker%20for%20Windows%20Installer.exe

$LocalTempDir = $env:TEMP; $DockerInstaller = "DockerInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('https://download.docker.com/win/stable/19507/Docker%20for%20Windows%20Installer.exe', "$LocalTempDir\$DockerInstaller"); & "$LocalTempDir\$DockerInstaller";