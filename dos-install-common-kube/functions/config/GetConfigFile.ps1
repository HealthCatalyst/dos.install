<#
  .SYNOPSIS
  GetConfigFile
  
  .DESCRIPTION
  GetConfigFile
  
  .INPUTS
  GetConfigFile - The name of GetConfigFile

  .OUTPUTS
  None
  
  .EXAMPLE
  GetConfigFile

  .EXAMPLE
  GetConfigFile


#>
function GetConfigFile() {
    [CmdletBinding()]
    param
    (

    )

    Write-Verbose 'GetConfigFile: Starting'
    [hashtable]$Return = @{} 

    $folder = $ENV:CatalystConfigPath
    if ([string]::IsNullOrEmpty("$folder")) {
        $folder = "c:\kubernetes\deployments"
    }
    if (Test-Path -Path $folder -PathType Container) {
        Write-Information -MessageData "Looking in $folder for *.json files"
        Write-Information -MessageData "You can set CatalystConfigPath environment variable to use a different path"

        $files = Get-ChildItem "$folder" -Filter *.json

        if ($files.Count -gt 0) {
            Write-Host "Choose config file from $folder"
            for ($i = 1; $i -le $files.count; $i++) {
                Write-Host "$i. $($($files[$i-1]).Name)"
            }    
            Write-Host "-------------"

            Do { $index = Read-Host "Enter number of file to use (1 - $($files.count))"}
            while ([string]::IsNullOrWhiteSpace($index)) 
            
            $Return.FilePath = $($($files[$index - 1]).FullName)
            return $Return
        }
    }

    Write-Information -MessageData "Sample config file: https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/deployments/sample.json"
    Do { $fullpath = Read-Host "Type full path to config file: "}
    while ([string]::IsNullOrWhiteSpace($fullpath))
    
    $Return.FilePath = $fullpath
    Write-Verbose 'GetConfigFile: Done'
    return $Return
}

Export-ModuleMember -Function "GetConfigFile"