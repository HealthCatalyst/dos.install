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

    $functions = ('SetStorageAccountNameIntoSecret')

    foreach($function in $functions)
    {
        Context "Test Function $function" {
            It "$function.ps1 should exist" {
                "$here\function-$function.ps1" | Should Exist
            }
            It "$function.ps1 should be an advanced function" {
                "$here\function-$function.ps1" | Should Contain 'function'
                "$here\function-$function.ps1" | Should Contain 'cmdletbinding'
                "$here\function-$function.ps1" | Should Contain 'param'
            }
            It "$function.ps1 should contain Write-Verbose blocks" {
                "$here\function-$function.ps1" | Should Contain 'Write-Verbose'
            }
            It "$function.ps1 is valid Powershell Code" {
                $psFile = Get-Content -Path "$here\function-$function.ps1" -ErrorAction Stop
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
                $errors.Count | Should Be 0
            }            
        }
        Context "$function has tests" {
            It "function-$function.Tests.ps1 should exist" {
                "function-$function.Tests.ps1" | Should Exist
            }
        }
    }
}