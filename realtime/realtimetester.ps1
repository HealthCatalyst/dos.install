param([ValidateNotNullOrEmpty()][string]$url, [ValidateNotNullOrEmpty()][string]$pwd)    
$version = "2018.05.11.01"
Write-Host "--- realtimetester.ps1 version $version ---"
Write-Host "url: $url"
Write-Host "pwd: $pwd"

# curl -useb https://raw.githubusercontent.com/HealthCatalyst/dos.install/release/realtime/realtimetester.ps1 | iex;

# show Information messages
$InformationPreference = "Continue"

if ($prerelease) {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/master"
}
else {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/release"
}
Write-Host "GITHUB_URL: $GITHUB_URL"

$set = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
$randomstring += $set | Get-Random

Write-Host "Powershell version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Build)"

$url = "https://github.com/HealthCatalyst/Fabric.Realtime.Tester/releases/download/1.0.0.1/RealtimeTester.zip"

DownloadFile -url $url -targetFile "RealtimeTester.zip"

# for some reason the download is not completely done by the time we get here
Write-Host "Waiting for 10 seconds"
Start-Sleep -Seconds 10

Expand-Archive -Path "RealtimeTester.zip" -DestinationPath "." -Force

