param([bool]$prerelease)
Write-Host "prerelease flag: $prerelease"

# curl -useb https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/azure/dos.ps1 | iex;
# Invoke-WebRequest -Uri https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/azure/dos.ps1 -OutFile dos.ps1

$set = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
$result += $set | Get-Random

if ($prerelease) {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/master"
    Write-Host "GITHUB_URL: $GITHUB_URL"
    $Script = Invoke-WebRequest -useb ${GITHUB_URL}/azure/main.ps1?f=$result;
    $ScriptBlock = [Scriptblock]::Create($Script.Content)
    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList (@("-prerelease 1"))
}
else {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/release"
    Write-Host "GITHUB_URL: $GITHUB_URL"
    $Script = Invoke-WebRequest -useb ${GITHUB_URL}/azure/main.ps1?f=$result;
    $ScriptBlock = [Scriptblock]::Create($Script.Content)
    Invoke-Command -ScriptBlock $ScriptBlock
    # Invoke-WebRequest -useb ${GITHUB_URL}/azure/main.ps1?f=$result | Invoke-Expression;
}

