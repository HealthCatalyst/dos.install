param([string]$branch)
Write-Host "branch: $branch"

$set = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
$result += $set | Get-Random

if(!$branch){
	$branch = "1"
}

if ($branch) {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/$branch"
    Write-Host "GITHUB_URL: $GITHUB_URL"
    Invoke-WebRequest -useb ${GITHUB_URL}/azure/main.ps1?f=$result -OutFile main.ps1
    .\main.ps1
}
else {
    $GITHUB_URL = "https://raw.githubusercontent.com/HealthCatalyst/dos.install/release"
    Write-Host "GITHUB_URL: $GITHUB_URL"
    $Script = Invoke-WebRequest -useb ${GITHUB_URL}/azure/main.ps1?f=$result;
    $ScriptBlock = [Scriptblock]::Create($Script.Content)
    Invoke-Command -ScriptBlock $ScriptBlock
    # Invoke-WebRequest -useb ${GITHUB_URL}/azure/main.ps1?f=$result | Invoke-Expression;
}

