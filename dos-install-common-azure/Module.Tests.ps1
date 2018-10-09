$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$module = "dos-install-common-azure"

Describe "$module Tests" {
    It "has the root module $module.psm1" {
        "$here\$module.psm1" | Should Exist
    }
    It "has the manifest file for $module.psm1" {
        "$here\$module.psd1" | Should Exist
    }
    It "$module folder has functions" {
        "$here\function-*.ps1" | Should Exist
    }
    It "$module is valid Powershell Code" {
        $psFile = Get-Content -Path "$here\$module.psm1" -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
        $errors.Count | Should Be 0
    }
}