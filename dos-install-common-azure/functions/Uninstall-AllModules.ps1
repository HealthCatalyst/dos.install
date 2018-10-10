<#
  .SYNOPSIS
  Uninstall-AllModules
  
  .DESCRIPTION
  Uninstall-AllModules
  
  .INPUTS
  Uninstall-AllModules - The name of Uninstall-AllModules

  .OUTPUTS
  None
  
  .EXAMPLE
  Uninstall-AllModules

  .EXAMPLE
  Uninstall-AllModules

    From https://docs.microsoft.com/en-us/powershell/azure/uninstall-azurerm-ps?view=azurermps-6.10.0
#>
function Uninstall-AllModules() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$TargetModule,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [switch]$Force
    )

    Write-Verbose 'Uninstall-AllModules: Starting'

    $AllModules = @()

    'Creating list of dependencies...'
    $target = Find-Module $TargetModule -RequiredVersion $version
    $target.Dependencies | ForEach-Object {
        $AllModules += New-Object -TypeName psobject -Property @{name = $_.name; version = $_.requiredversion}
    }
    $AllModules += New-Object -TypeName psobject -Property @{name = $TargetModule; version = $Version}

    foreach ($module in $AllModules) {
        Write-Host ('Uninstalling {0} version {1}' -f $module.name, $module.version)
        try {
            Uninstall-Module -Name $module.name -RequiredVersion $module.version -Force:$Force -ErrorAction Stop
        }
        catch {
            Write-Host ("`t" + $_.Exception.Message)
        }
    }

    Write-Verbose 'Uninstall-AllModules: Done'

}