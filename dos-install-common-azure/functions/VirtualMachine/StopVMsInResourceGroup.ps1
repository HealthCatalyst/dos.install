<#
.SYNOPSIS
StopVMsInResourceGroup

.DESCRIPTION
StopVMsInResourceGroup

.INPUTS
StopVMsInResourceGroup - The name of StopVMsInResourceGroup

.OUTPUTS
None

.EXAMPLE
StopVMsInResourceGroup

.EXAMPLE
StopVMsInResourceGroup


#>
function StopVMsInResourceGroup()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'StopVMsInResourceGroup: Starting'
    $vms = $(Get-AzureRmVM -ResourceGroupName "$resourceGroup")

    foreach($vm in $vms){
        Write-Host "Stopping $($vm.Name)"
        Stop-AzureRmVM -ResourceGroupName $resourceGroup -Name $vm.Name -Force -Verbose
    }

    Write-Verbose 'StopVMsInResourceGroup: Done'

}

Export-ModuleMember -Function 'StopVMsInResourceGroup'