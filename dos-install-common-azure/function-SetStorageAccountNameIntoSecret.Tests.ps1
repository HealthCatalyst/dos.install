$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$filename = "function-SetStorageAccountNameIntoSecret.ps1"

Describe "$filename Tests" {
    It "$filename is valid Powershell Code" {
        $psFile = Get-Content -Path "$here\$filename" -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
        $errors.Count | Should Be 0
    }
}