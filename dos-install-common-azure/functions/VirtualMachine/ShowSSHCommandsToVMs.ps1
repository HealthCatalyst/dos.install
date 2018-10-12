<#
.SYNOPSIS
ShowSSHCommandsToVMs

.DESCRIPTION
ShowSSHCommandsToVMs

.INPUTS
ShowSSHCommandsToVMs - The name of ShowSSHCommandsToVMs

.OUTPUTS
None

.EXAMPLE
ShowSSHCommandsToVMs

.EXAMPLE
ShowSSHCommandsToVMs


#>
function ShowSSHCommandsToVMs() {
    [CmdletBinding()]
    param
    (
    )

    Write-Verbose 'ShowSSHCommandsToVMs: Starting'
    $defaultResourceGroup = ReadSecretData -secretname azure-secret -valueName resourcegroup

    if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
        Do {
            $resourceGroup = Read-Host "Resource Group: (default: $defaultResourceGroup)"
            if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
                $resourceGroup = $defaultResourceGroup
            }
        }
        while ([string]::IsNullOrWhiteSpace($resourceGroup))
    }

    $location = az group show --name $resourceGroup --query "location" -o tsv

    $localFolder = Read-Host "Folder to store SSH keys (default: c:\kubernetes)"
    if ([string]::IsNullOrWhiteSpace($localFolder)) {$localFolder = "C:\kubernetes"}

    $folderForSSHKey = "$localFolder\ssh\$resourceGroup"
    $SSH_PRIVATE_KEY_FILE = "$folderForSSHKey\id_rsa"
    $SSH_PRIVATE_KEY_FILE_UNIX_PATH = "/" + (($SSH_PRIVATE_KEY_FILE -replace "\\", "/") -replace ":", "").ToLower().Trim("/")
    # $MASTER_VM_NAME = "${resourceGroup}.${location}.cloudapp.azure.com"
    # Write-Host "You can connect to master VM in Git Bash for debugging using:"
    # Write-Host "ssh -i ${SSH_PRIVATE_KEY_FILE_UNIX_PATH} azureuser@${MASTER_VM_NAME}"

    $virtualmachines = az vm list -g $resourceGroup --query "[?storageProfile.osDisk.osType != 'Windows'].name" -o tsv
    ForEach ($vm in $virtualmachines) {
        $firstpublicip = az vm list-ip-addresses -g $resourceGroup -n $vm --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv
        if ([string]::IsNullOrEmpty($firstpublicip)) {
            $firstpublicip = az vm show -g $resourceGroup -n $vm -d --query privateIps -otsv
            $firstpublicip = $firstpublicip.Split(",")[0]
        }
        Write-Host "Connect to ${vm}:"
        Write-Host "ssh -i ${SSH_PRIVATE_KEY_FILE_UNIX_PATH} azureuser@${firstpublicip}"
    }

    Write-Host "Command to show errors: sudo journalctl -xef --priority 0..3"
    Write-Host "Command to see apiserver logs: sudo journalctl -fu kube-apiserver"
    Write-Host "Command to see kubelet status: sudo systemctl status kubelet"
    # sudo systemctl restart kubelet.service
    # sudo service kubelet status
    # /var/log/pods

    Write-Host "Cheat Sheet for journalctl: https://www.cheatography.com/airlove/cheat-sheets/journalctl/"
    # systemctl list-unit-files | grep .service | grep enabled
    # https://askubuntu.com/questions/795226/how-to-list-all-enabled-services-from-systemctl

    # restart VM: az vm restart -g MyResourceGroup -n MyVm
    # list vm sizes available: az vm list-sizes --location "eastus" --query "[].name"

    Write-Verbose 'ShowSSHCommandsToVMs: Done'

}

Export-ModuleMember -Function 'ShowSSHCommandsToVMs'