<#
.SYNOPSIS
RestartVMsInResourceGroup

.DESCRIPTION
RestartVMsInResourceGroup

.INPUTS
RestartVMsInResourceGroup - The name of RestartVMsInResourceGroup

.OUTPUTS
None

.EXAMPLE
RestartVMsInResourceGroup

.EXAMPLE
RestartVMsInResourceGroup


#>
function RestartVMsInResourceGroup() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $resourceGroup
    )

    Write-Verbose 'RestartVMsInResourceGroup: Starting'
    [hashtable]$Return = @{}

    # az vm run-command invoke -g Prod-Kub-AHMN-RG -n k8s-master-37819884-0 --command-id RunShellScript --scripts "apt-get update && sudo apt-get upgrade"
    Write-Information -MessageData "Restarting VMs in resource group: ${resourceGroup}: $(az vm list -g $resourceGroup --query "[].name" -o tsv)"
    az vm restart --ids $(az vm list -g $resourceGroup --query "[].id" -o tsv)

    Write-Information -MessageData "Waiting for VMs to restart: $(az vm list -g $resourceGroup --query "[].name" -o tsv)"
    $virtualmachines = az vm list -g $resourceGroup --query "[].name" -o tsv
    ForEach ($vm in $virtualmachines) {

        Write-Information -MessageData "Waiting on $vm"
        Do {
            Start-Sleep -Seconds 1
            $state = az vm show -g $resourceGroup -n $vm -d --query "powerState";
            Write-Information -MessageData "Status of ${vm}: ${state}"
        }
        while (!($state = "VM running"))
    }

    # sudo systemctl restart etcd
    # ForEach ($vm in $virtualmachines) {
    #     if ($vm -match "master" ) {
    #         Write-Information -MessageData "Sending command to master($vm) to restart etcd due to bug: https://github.com/Azure/acs-engine/issues/2282"
    #         az vm run-command invoke -g $resourceGroup -n $vm --command-id RunShellScript --scripts "systemctl restart etcd"
    #     }
    # }

    # systemctl enable etcd.service


    Write-Verbose 'RestartVMsInResourceGroup: Done'
    return $Return

}

Export-ModuleMember -Function 'RestartVMsInResourceGroup'