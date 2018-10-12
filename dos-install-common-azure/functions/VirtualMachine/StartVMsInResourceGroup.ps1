<#
.SYNOPSIS
StartVMsInResourceGroup

.DESCRIPTION
StartVMsInResourceGroup

.INPUTS
StartVMsInResourceGroup - The name of StartVMsInResourceGroup

.OUTPUTS
None

.EXAMPLE
StartVMsInResourceGroup

.EXAMPLE
StartVMsInResourceGroup


#>
function StartVMsInResourceGroup() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'StartVMsInResourceGroup: Starting'
    $vms = $(Get-AzureRmVM -ResourceGroupName "$resourceGroup")

    foreach($vm in $vms){
        Write-Host "Stopping $($vm.Name)"
        Start-AzureRmVM -ResourceGroupName $resourceGroup -Name $vm.Name -Force -Verbose
    }

    Write-Verbose 'StartVMsInResourceGroup: Done'
}

Export-ModuleMember -Function 'StartVMsInResourceGroup'