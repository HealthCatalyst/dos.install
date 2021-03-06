# This file contains common functions for Azure
# 
$versioncommon = "2018.06.05.01"

Write-Information -MessageData "---- Including common.ps1 version $versioncommon -----"
function global:GetCommonVersion() {
    return $versioncommon
}

function global:Coalesce($a, $b) { if ($a -ne $null) { $a } else { $b } }

function global:DeleteAzureFileShare([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $sharename, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $storageAccountConnectionString) {
    [hashtable]$Return = @{} 

    if ($(az storage share exists -n $sharename --connection-string $storageAccountConnectionString --query "exists" -o tsv)) {
        Write-Information -MessageData "Deleting the file share: $sharename"
        az storage share delete -n $sharename --connection-string $storageAccountConnectionString
    
        
        Write-Information -MessageData "Waiting for completion of delete for the file share: $sharename"        
        Do {
            Start-Sleep -Seconds 5 
            $shareExists = $(az storage share exists -n $sharename --connection-string $storageAccountConnectionString --query "exists" -o tsv)
            Write-Information -MessageData "."
        }
        while ($shareExists -ne "false")    
    }

    return $Return
}
function global:CreateShareInStorageAccount([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $storageAccountName, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $sharename, $deleteExisting) { 
    [hashtable]$Return = @{} 

    [int]$filesharesize = 128

    $storageAccountConnectionString = az storage account show-connection-string -n $storageAccountName -g $resourceGroup -o tsv
    
    # Write-Information -MessageData "Storage connection string: $storageAccountConnectionString"

    if ($deleteExisting) {
        DeleteAzureFileShare -sharename $sharename -storageAccountConnectionString $storageAccountConnectionString
    }

    if ($(az storage share exists -n $sharename --connection-string $storageAccountConnectionString --query "exists" -o tsv) -eq "false") {
        Write-Information -MessageData "Creating the file share: $sharename"        
        az storage share create -n $sharename --connection-string $storageAccountConnectionString --quota $filesharesize       

        Write-Information -MessageData "Waiting for completion of create for the file share: $sharename"        
        Do {
            $shareExists = $(az storage share exists -n $sharename --connection-string $storageAccountConnectionString --query "exists" -o tsv)
            Write-Host "."
            Start-Sleep -Seconds 5 
        }
        while ($shareExists -eq "false")    
    }
    else {
        Write-Information -MessageData "File share already exists: $sharename"         
    }
    return $Return

}
function global:CreateShare([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $sharename, $deleteExisting) {
    [hashtable]$Return = @{} 

    $storageAccountName = ReadSecretData -secretname azure-secret -valueName azurestorageaccountname 
    
    CreateShareInStorageAccount -storageAccountName $storageAccountName -resourceGroup $resourceGroup -sharename $sharename -deleteExisting $deleteExisting
    return $Return
}


# helper functions for subnet match
# from https://gallery.technet.microsoft.com/scriptcenter/Start-and-End-IP-addresses-bcccc3a9
function global:Get-FirstIP {
    <# 
  .SYNOPSIS  
    Get the IP addresses in a range 
  .EXAMPLE 
   Get-IPrange -start 192.168.8.2 -end 192.168.8.20 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.3 -cidr 24 
#> 
 
    param 
    ( 
        [string]$start, 
        [string]$end, 
        [string]$ip, 
        [string]$mask, 
        [int]$cidr 
    ) 
 
    function IP-toINT64 () { 
        param ($ip) 
 
        $octets = $ip.split(".") 
        return [int64]([int64]$octets[0] * 16777216 + [int64]$octets[1] * 65536 + [int64]$octets[2] * 256 + [int64]$octets[3]) 
    } 
 
    function INT64-toIP() { 
        param ([int64]$int) 

        return (([math]::truncate($int / 16777216)).tostring() + "." + ([math]::truncate(($int % 16777216) / 65536)).tostring() + "." + ([math]::truncate(($int % 65536) / 256)).tostring() + "." + ([math]::truncate($int % 256)).tostring() )
    } 
 
    if ($ip.Contains("/")) {
        $Temp = $ip.Split("/")
        $ip = $Temp[0]
        $cidr = $Temp[1]
    }

    if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)} 
    if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1" * $cidr + "0" * (32 - $cidr)), 2)))) } 
    if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)} 
    if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)} 
    if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))} 
 
    if ($ip) { 
        $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
        $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
    }
    else { 
        $startaddr = IP-toINT64 -ip $start 
        $endaddr = IP-toINT64 -ip $end 
    } 
 
    # https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/features.md#feat-custom-vnet
    $startaddr = $startaddr + 239 # skip the first few since they are reserved
    INT64-toIP -int $startaddr
}

function global:SetupCronTab([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
    [hashtable]$Return = @{} 

    $virtualmachines = az vm list -g $resourceGroup --query "[?storageProfile.osDisk.osType != 'Windows'].name" -o tsv
    ForEach ($vm in $virtualmachines) {
        if ($vm -match "master" ) {
            Write-Information -MessageData "Running script on $vm"
            # https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash-automatically-without-the-interactive-editor
            $cmd = @'
whoami;
sudo mkdir -p /opt/healthcatalyst;
sudo curl -sSL https://raw.githubusercontent.com/HealthCatalyst/dos.install/master/azure/restartkubedns.txt -o /opt/healthcatalyst/restartkubedns.sh;
sudo chmod +x /opt/healthcatalyst/restartkubedns.sh;
export EDITOR=/bin/nano;
croncmd='/opt/healthcatalyst/restartkubedns.sh >> /tmp/restartkubedns.log 2>&1';
cronjob='*/10 * * * *';
( crontab -l | grep -v -F 'restartkubedns.sh' ; echo \"$cronjob $croncmd\" ) | crontab - ;
crontab -l;
'@
            $cmd = $cmd -replace "`n", "" -replace "`r", ""
            az vm run-command invoke -g $resourceGroup -n $vm --command-id RunShellScript --scripts "$cmd"
        }
    }
    return $Return
}

function global:UpdateOSInVMs([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
    [hashtable]$Return = @{} 

    $virtualmachines = az vm list -g $resourceGroup --query "[?storageProfile.osDisk.osType != 'Windows'].name" -o tsv
    ForEach ($vm in $virtualmachines) {
        Write-Information -MessageData "Updating OS in vm: $vm"
        $cmd = "apt-get update && apt-get -y upgrade"
        az vm run-command invoke -g $resourceGroup -n $vm --command-id RunShellScript --scripts "$cmd"
    }
    return $Return
}


function global:RestartVMsInResourceGroup([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
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
    
    return $Return
}

function global:FixEtcdRestartIssueOnMaster([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {

    [hashtable]$Return = @{} 

    $virtualmachines = az vm list -g $resourceGroup --query "[].name" -o tsv
    ForEach ($vm in $virtualmachines) {
        if ($vm -match "master" ) {
            Write-Information -MessageData "Sending command to master($vm) to enable etcd due to bug: https://github.com/Azure/acs-engine/issues/2282"
            # https://github.com/Azure/acs-engine/pull/2329/commits/e3ef0578f268bf00e6065414acffdfd7ebb4e90b
            az vm run-command invoke -g $resourceGroup -n $vm --command-id RunShellScript --scripts "systemctl enable etcd.service"
        }
    }
    return $Return
}


function global:SetHostFileInVms( [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
    [hashtable]$Return = @{} 

    $AKS_PERS_LOCATION = az group show --name $resourceGroup --query "location" -o tsv

    $MASTER_VM_NAME = "${resourceGroup}.${AKS_PERS_LOCATION}.cloudapp.azure.com"
    $MASTER_VM_NAME = $MASTER_VM_NAME.ToLower()

    Write-Information -MessageData "Creating hosts entries"
    $fullCmdToUpdateHostsFiles = ""
    $cmdToRemovePreviousHostEntries = ""
    $cmdToAddNewHostEntries = ""
    $virtualmachines = az vm list -g $resourceGroup --query "[?storageProfile.osDisk.osType != 'Windows'].name" -o tsv
    ForEach ($vm in $virtualmachines) {
        $firstprivateip = az vm list-ip-addresses -g $resourceGroup -n $vm --query "[].virtualMachine.network.privateIpAddresses[0]" -o tsv
        # $privateiplist= az vm show -g $AKS_PERS_RESOURCE_GROUP -n $vm -d --query privateIps -otsv
        Write-Information -MessageData "$firstprivateip $vm"

        $cmdToRemovePreviousHostEntries = $cmdToRemovePreviousHostEntries + "grep -v '${vm}' - | "
        $cmdToAddNewHostEntries = $cmdToAddNewHostEntries + " && echo '$firstprivateip $vm'"
        if ($vm -match "master" ) {
            Write-Information -MessageData "$firstprivateip $MASTER_VM_NAME"
            $cmdToRemovePreviousHostEntries = $cmdToRemovePreviousHostEntries + "grep -v '${MASTER_VM_NAME}' - | "
            $cmdToAddNewHostEntries = $cmdToAddNewHostEntries + " && echo '$firstprivateip ${MASTER_VM_NAME}'"
        }
    }

    $fullCmdToUpdateHostsFiles = "cat /etc/hosts | $cmdToRemovePreviousHostEntries (cat $cmdToAddNewHostEntries ) | tee /etc/hosts; cat /etc/hosts"

    Write-Information -MessageData "Command to send to VM"
    Write-Information -MessageData "$fullCmdToUpdateHostsFiles"

    ForEach ($vm in $virtualmachines) {
        Write-Information -MessageData "Sending command to $vm"
        az vm run-command invoke -g $resourceGroup -n $vm --command-id RunShellScript --scripts "$fullCmdToUpdateHostsFiles"
    }
    return $Return
}


function global:CleanResourceGroup([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $location, [string] $vnet, [string] $subnet, [string] $subnetResourceGroup, [string] $storageAccount) {
    [hashtable]$Return = @{} 

    Write-Information -MessageData "checking if resource group already exists"
    $resourceGroupExists = az group exists --name ${resourceGroup}
    if ($resourceGroupExists -eq "true") {

        if ($(az vm list -g $resourceGroup --query "[].id" -o tsv).length -ne 0) {
            Write-Warning "The resource group [${resourceGroup}] already exists with the following VMs"
            az resource list --resource-group "${resourceGroup}" --resource-type "Microsoft.Compute/virtualMachines" --query "[].id"
        
            # Do { $confirmation = Read-Host "Would you like to continue (all above resources will be deleted)? (y/n)"}
            # while ([string]::IsNullOrWhiteSpace($confirmation)) 

            # if ($confirmation -eq 'n') {
            #     Read-Host "Hit ENTER to exit"
            #     exit 0
            # }    
        }
        else {
            Write-Information -MessageData "The resource group [${resourceGroup}] already exists but has no VMs"
        }

        if ("$vnet") {
            # Write-Information -MessageData "removing route table"
            # az network vnet subnet update -n "${subnet}" -g "${subnetResourceGroup}" --vnet-name "${vnet}" --route-table ""
        }
        Write-Information -MessageData "cleaning out the existing group: [$resourceGroup]"
        #az group delete --name $resourceGroup --verbose

        if ($(az vm list -g $resourceGroup --query "[].id" -o tsv).length -ne 0) {
            Write-Information -MessageData "delete the VMs first (this can take 5-10 minutes)"
            az vm delete --ids $(az vm list -g $resourceGroup --query "[].id" -o tsv) --verbose --yes
        }

        if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/networkInterfaces" --query "[].id" -o tsv ).length -ne 0) {
            Write-Information -MessageData "delete the nics"
            az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/networkInterfaces" --query "[].id" -o tsv )  --verbose
        }

        if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Compute/disks" --query "[].id" -o tsv ).length -ne 0) {
            Write-Information -MessageData "delete the disks"
            az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Compute/disks" --query "[].id" -o tsv )
        }

        if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Compute/availabilitySets" --query "[].id" -o tsv ).length -ne 0) {
            Write-Information -MessageData "delete the availabilitysets"
            az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Compute/availabilitySets" --query "[].id" -o tsv )
        }

        if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/loadBalancers" --query "[].id" -o tsv ).length -ne 0) {
            Write-Information -MessageData "delete the load balancers"
            az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/loadBalancers" --query "[].id" -o tsv )
        }

        if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/applicationGateways" --query "[].id" -o tsv ).length -ne 0) {
            Write-Information -MessageData "delete the application gateways"
            az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/applicationGateways" --query "[].id" -o tsv )
        }
    
        if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Storage/storageAccounts" --query "[].id" -o tsv | Where-Object {!"$_".EndsWith("$storageAccount")}).length -ne 0) {
            Write-Information -MessageData "delete the storage accounts EXCEPT storage account we created in the past"
            az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Storage/storageAccounts" --query "[].id" -o tsv | Where-Object {!"$_".EndsWith("${storageAccount}")} )
            # az resource list --resource-group fabricnlp3 --resource-type "Microsoft.Storage/storageAccounts" --query "[].id" -o tsv | ForEach-Object { if (!"$_".EndsWith("${resourceGroup}storage")) {  az resource delete --ids "$_" }}    
        }
        if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/publicIPAddresses" --query "[].id" -o tsv | Where-Object {!"$_".EndsWith("PublicIP")}).length -ne 0) {
            Write-Information -MessageData "delete the public IPs EXCEPT Ingress IP we created in the past"
            az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/publicIPAddresses" --query "[].id" -o tsv | Where-Object {!"$_".EndsWith("PublicIP")} )
        }
    
        if (("$vnet") ) {
            if (![string]::IsNullOrWhiteSpace($(az network vnet subnet show -n "${subnet}" -g "${subnetResourceGroup}" --vnet-name "${vnet}" --query "networkSecurityGroup.id"))) {
                # Write-Information -MessageData "Switching the subnet to a temp route table and tempnsg so we can delete the old route table and nsg"

                # $routeid = $(az network route-table show --name temproutetable --resource-group $resourceGroup --query "id" -o tsv)
                # if ([string]::IsNullOrWhiteSpace($routeid)) {
                #     Write-Information -MessageData "create temproutetable"
                #     $routeid = az network route-table create --name temproutetable --resource-group $resourceGroup --query "id" -o tsv   
                # }
                # $routeid = $(az network route-table show --name temproutetable --resource-group $resourceGroup --query "id" -o tsv)
                # Write-Information -MessageData "temproutetable: $routeid"

                # $nsg = $(az network nsg show --name tempnsg --resource-group $resourceGroup --query "id" -o tsv)
                # if ([string]::IsNullOrWhiteSpace($nsg)) {
                #     Write-Information -MessageData "create tempnsg"
                #     $nsg = az network nsg create --name tempnsg --resource-group $resourceGroup --query "id" -o tsv   
                # }
                # $nsg = $(az network nsg show --name tempnsg --resource-group $resourceGroup --query "id" -o tsv)
                # Write-Information -MessageData "tempnsg: $nsg"
        
                Write-Information -MessageData "Updating the subnet"
                az network vnet subnet update -n "${subnet}" -g "${subnetResourceGroup}" --vnet-name "${vnet}" --route-table="" --network-security-group=""

                #az network vnet subnet update -n "${subnet}" -g "${subnetResourceGroup}" --vnet-name "${vnet}" --route-table "$routeid" --network-security-group "$nsg"
            }
        
            if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/routeTables" --query "[?name != 'temproutetable'].id" -o tsv ).length -ne 0) {
                Write-Information -MessageData "delete the routes EXCEPT the temproutetable we just created"
                az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/routeTables" --query "[?name != 'temproutetable'].id" -o tsv)
            }
            if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/networkSecurityGroups" --query "[?name != 'tempnsg'].id" -o tsv).length -ne 0) {
                Write-Information -MessageData "delete the nsgs EXCEPT the tempnsg we just created"
                az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/networkSecurityGroups" --query "[?name != 'tempnsg'].id" -o tsv)
            }
        }
        else {
            if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/routeTables" --query "[].id" -o tsv).length -ne 0) {
                Write-Information -MessageData "delete the routes EXCEPT the temproutetable we just created"
                az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/routeTables" --query "[].id" -o tsv)
            }
            $networkSecurityGroup = "$($resourceGroup.ToLower())-nsg"
            if ($(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/networkSecurityGroups" --query "[?name != '${$networkSecurityGroup}'].id" -o tsv ).length -ne 0) {
                Write-Information -MessageData "delete the network security groups"
                az resource delete --ids $(az resource list --resource-group $resourceGroup --resource-type "Microsoft.Network/networkSecurityGroups" --query "[?name != '${$networkSecurityGroup}'].id" -o tsv )
            }
    
        }
        # note: do not delete the Microsoft.Network/publicIPAddresses otherwise the loadBalancer will get a new IP
    }
    else {
        Write-Information -MessageData "Create the Resource Group"
        az group create --name $resourceGroup --location $location --verbose
    }
    return $Return
}

function global:GetStorageAccountName([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
    [hashtable]$Return = @{} 

    $storageAccountName = "${resourceGroup}storage"
    # remove non-alphanumeric characters and use lowercase since azure doesn't allow those in a storage account
    $storageAccountName = $storageAccountName -replace '[^a-zA-Z0-9]', ''
    $storageAccountName = $storageAccountName.ToLower()
    if ($storageAccountName.Length -gt 24) {
        $storageAccountName = $storageAccountName.Substring(0, 24) # azure does not allow names longer than 24
    }

    $Return.StorageAccountName = $storageAccountName
    return $Return
    
}
function global:CreateStorageIfNotExists([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, $deleteStorageAccountIfExists) {
    #Create an hashtable variable 
    [hashtable]$Return = @{} 

    Write-Information -MessageData "Checking to see if storage account exists"

    $location = az group show --name $resourceGroup --query "location" -o tsv

    if ([string]::IsNullOrWhiteSpace($storageAccountName)) {
        $storageAccountName = $(GetStorageAccountName -resourceGroup $resourceGroup).StorageAccountName
        Write-Information -MessageData "Using storage account: [$storageAccountName]"
    }
    Write-Information -MessageData "Checking to see if storage account exists"

    $storageAccountConnectionString = az storage account show-connection-string --name $storageAccountName --resource-group $resourceGroup --query "connectionString" --output tsv
    [Console]::ResetColor()
    if (![string]::IsNullOrEmpty($storageAccountConnectionString)) {
        if ($deleteStorageAccountIfExists) {
            Write-Warning "Storage account, [$storageAccountName], already exists.  Deleting it will remove this data permanently"
            Do { $confirmation = Read-Host "Delete storage account: (WARNING: deletes data) (y/n)"}
            while ([string]::IsNullOrWhiteSpace($confirmation)) 
    
            if ($confirmation -eq 'y') {
                az storage account delete -n $storageAccountName -g $resourceGroup --yes
                Write-Information -MessageData "Creating storage account: [${storageAccountName}]"
                # https://docs.microsoft.com/en-us/azure/storage/common/storage-quickstart-create-account?tabs=azure-cli
                az storage account create -n $storageAccountName -g $resourceGroup -l $location --kind StorageV2 --sku Standard_LRS                       
            }    
        }
    }
    else {
        Write-Information -MessageData "Checking if storage account name is valid"
        $storageAccountCanBeCreated = az storage account check-name --name $storageAccountName --query "nameAvailable" --output tsv        
        if ($storageAccountCanBeCreated -ne "True" ) {
            Write-Warning "$(az storage account check-name --name $storageAccountName --query 'message' --output tsv)"
            Write-Error "$storageAccountName is not a valid storage account name"
        }
        else {
            Write-Information -MessageData "Creating storage account: [${storageAccountName}]"
            az storage account create -n $storageAccountName -g $resourceGroup -l $location --kind StorageV2 --sku Standard_LRS                       
        }
    }

    $storageKey = az storage account keys list --resource-group $resourceGroup --account-name $storageAccountName --query "[0].value" --output tsv
    
    $Return.STORAGE_KEY = $storageKey
    $Return.AKS_PERS_STORAGE_ACCOUNT_NAME = $storageAccountName
    return $Return
}


function global:GetSubnetId([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subscriptionId, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subnetResourceGroup, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $vnetName, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subnetName) {

    [hashtable]$Return = @{} 

    $Return.SubnetId = "/subscriptions/${subscriptionId}/resourceGroups/${subnetResourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}"
    Return $Return                     
}
function global:GetVnetInfo([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subscriptionId, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subnetResourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $vnetName, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subnetName) {
    [hashtable]$Return = @{} 

    # verify the subnet exists
    $mysubnetid = $(GetSubnetId -subscriptionId $subscriptionId -subnetResourceGroup $subnetResourceGroup -vnetName $vnetName -subnetName $subnetName).SubnetId
    
    $subnetexists = az resource show --ids $mysubnetid --query "id" -o tsv
    if (!"$subnetexists") {
        Write-Host "The subnet was not found: $mysubnetid"
        Read-Host "Hit ENTER to exit"
        exit 0        
    }
    else {
        Write-Information -MessageData "Found subnet: [$mysubnetid]"
    }
        
    Write-Information -MessageData "Looking up CIDR for Subnet: [${subnetName}]"
    $subnetCidr = az network vnet subnet show --name ${subnetName} --resource-group ${subnetResourceGroup} --vnet-name ${vnetname} --query "addressPrefix" --output tsv
    
    Write-Information -MessageData "Subnet CIDR=[$subnetCidr]"
    # suggest and ask for the first static IP to use
    $firstStaticIP = ""
    $suggestedFirstStaticIP = Get-FirstIP -ip ${subnetCidr}
    
    # $firstStaticIP = Read-Host "First static IP: (default: $suggestedFirstStaticIP )"
        
    if ([string]::IsNullOrWhiteSpace($firstStaticIP)) {
        $firstStaticIP = "$suggestedFirstStaticIP"
    }
    
    Write-Information -MessageData "First static IP=[${firstStaticIP}]"

    $Return.AKS_FIRST_STATIC_IP = $firstStaticIP
    $Return.AKS_SUBNET_ID = $mysubnetid
    $Return.AKS_SUBNET_CIDR = $subnetCidr
    
    #Return the hashtable
    Return $Return                 
}
function global:Test-CommandExists {
    Param ($command)

    # from https://blogs.technet.microsoft.com/heyscriptingguy/2013/02/19/use-a-powershell-function-to-see-if-a-command-exists/
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {if (Get-Command $command) {RETURN $true}}
    Catch {Write-Information -MessageData "$command does not exist"; RETURN $false}
    Finally {$ErrorActionPreference = $oldPreference}
} #end function test-CommandExists

function global:Get-ProcessByPort( [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] [int] $Port ) {    
    $netstat = netstat.exe -ano | Select-Object -Skip 4
    $p_line = $netstat | Where-Object { $p = ( -split $_ | Select-Object -Index 1) -split ':' | Select-Object -Last 1; $p -eq $Port } | Select-Object -First 1
    if (!$p_line) { return; } 
    $p_id = $p_line -split '\s+' | Select-Object -Last 1
    return $p_id;
}

function global:FindOpenPort($portArray) {
    [hashtable]$Return = @{} 

    ForEach ($port in $portArray) {
        $result = Get-ProcessByPort $port
        if ([string]::IsNullOrEmpty($result)) {
            $Return.Port = $port
            return $Return
        }
    }   
    $Return.Port = 0

    return $Return
}

function global:AddFolderToPathEnvironmentVariable([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $folder) {
    [hashtable]$Return = @{} 

    # add the c:\kubernetes folder to system PATH
    Write-Information -MessageData "Checking if $folder is in PATH"
    $current_path = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
    $pathItems = ($current_path).split(";")
    if ( $pathItems -notcontains "$folder") {
        Write-Information -MessageData "Adding $folder to system path"
        $newpath = "$folder;$current_path"
        [Environment]::SetEnvironmentVariable( "PATH", $newpath, [System.EnvironmentVariableTarget]::User )
        # [Environment]::SetEnvironmentVariable( "Path", $newpath, [System.EnvironmentVariableTarget]::Machine )
        # for current session set the PATH too.  the above only takes effect if powershell is reopened
        $ENV:PATH = "$folder;$ENV:PATH"
        Write-Information -MessageData "PATH for current powershell session"
        Write-Information -MessageData ($env:path).split(";")
    }
    else {
        Write-Information -MessageData "$folder is already in PATH"
    }
    return $Return
}
function global:DownloadAzCliIfNeeded([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $version) {
    [hashtable]$Return = @{} 

    # install az cli from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
    $desiredAzClVersion = $version
    $downloadazcli = $False
    if (!(Test-CommandExists az)) {
        $downloadazcli = $True
    }
    else {
        $azcurrentversion = $(az -v | Select-String "azure-cli" | Select-Object -exp line)
        Write-Information -MessageData "Desired az cli: [$desiredAzClVersion], Found az cli: [$azcurrentversion]"
        $justVersion = [System.Version] $azcurrentversion.Substring($azcurrentversion.IndexOf('(') + 1, $azcurrentversion.IndexOf(')') - $azcurrentversion.IndexOf('(') - 1)
        # we should get: azure-cli (2.0.22)
        if ($justVersion -lt $desiredAzClVersion) {
            Write-Information -MessageData "az version $azcurrentversion is not the same as desired version: $desiredAzClVersion"
            $downloadazcli = $True
        }
    }

    if ($downloadazcli) {
        $azCliFile = ([System.IO.Path]::GetTempPath() + ("azure-cli-${desiredAzClVersion}.msi"))
        # $url = "https://azurecliprod.blob.core.windows.net/msi/azure-cli-latest.msi"
        $url = "https://azurecliprod.blob.core.windows.net/msi/azure-cli-${desiredAzClVersion}.msi"
        Write-Information -MessageData "Downloading azure-cli-${desiredAzClVersion}.msi from url $url to $azCliFile"
        If (Test-Path $azCliFile) {
            Remove-Item $azCliFile -Force
        }

        DownloadFile -url $url -targetFile $azCliFile

        # for some reason the download is not completely done by the time we get here
        Write-Information -MessageData "Waiting for 10 seconds"
        Start-Sleep -Seconds 10
        # https://kevinmarquette.github.io/2016-10-21-powershell-installing-msi-files/
        Write-Information -MessageData "Running MSI to install az cli: $azCliFile.  This may take a few minutes."
        $azCliInstallLog = ([System.IO.Path]::GetTempPath() + ('az-cli-latest.log'))
        # msiexec flags: https://msdn.microsoft.com/en-us/library/windows/desktop/aa367988(v=vs.85).aspx
        # Start-Process -Verb runAs msiexec.exe -Wait -ArgumentList "/i $azCliFile /qn /L*e $azCliInstallLog"
        Start-Process -Verb runAs msiexec.exe -Wait -ArgumentList "/i $azCliFile"
        Write-Information -MessageData "Finished installing az-cli-latest.msi"
    }
    return $Return
}

function global:CreateSSHKey([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $localFolder) {
    #Create an hashtable variable 
    [hashtable]$Return = @{} 

    $folderForSSHKey = "$localFolder\ssh\$resourceGroup"

    if (!(Test-Path -Path "$folderForSSHKey")) {
        Write-Information -MessageData "$folderForSSHKey does not exist.  Creating it..."
        New-Item -ItemType directory -Path "$folderForSSHKey"
    }
    
    # check if SSH key is present.  If not, generate it
    $privateKeyFile = "$folderForSSHKey\id_rsa"
    $privateKeyFileUnixPath = "/" + (($privateKeyFile -replace "\\", "/") -replace ":", "").ToLower().Trim("/")    
    
    if (!(Test-Path "$privateKeyFile")) {
        Write-Host "SSH key does not exist in $privateKeyFile."
        Write-Host "Please open Git Bash and run:"
        Write-Host "ssh-keygen -t rsa -b 2048 -q -N '' -C azureuser@linuxvm -f $privateKeyFileUnixPath"
        Read-Host "Hit ENTER after you're done"
    }
    else {
        Write-Information -MessageData "SSH key already exists at $privateKeyFile so using it"
    }
    
    $publicKeyFile = "$folderForSSHKey\id_rsa.pub"
    $sshKey = Get-Content "$publicKeyFile" -First 1
    Write-Information -MessageData "SSH Public Key=$sshKey"

    
    $Return.AKS_SSH_KEY = $sshKey
    $Return.SSH_PUBLIC_KEY_FILE = $publicKeyFile
    $Return.SSH_PRIVATE_KEY_FILE_UNIX_PATH = $privateKeyFileUnixPath

    #Return the hashtable
    Return $Return     
        
}

function global:CheckUserIsLoggedIn() {

    #Create an hashtable variable 
    [hashtable]$Return = @{} 

    Write-Information -MessageData "Checking if you're already logged into Azure..."

    # to print out the result to screen also use: <command> | Tee-Object -Variable cmdOutput
    $loggedInUser = $(az account show --query "user.name"  --output tsv)
    
    # get azure login and subscription
    Write-Information -MessageData "user ${loggedInUser}"
    
    if ( "$loggedInUser" ) {
        $subscriptionName = az account show --query "name"  --output tsv
        # Write-Information -MessageData "You are currently logged in as [$loggedInUser] into subscription [$subscriptionName]"
        
        # Do { $confirmation = Read-Host "Do you want to use this account? (y/n)"}
        # while ([string]::IsNullOrWhiteSpace($confirmation))
    
        # if ($confirmation -eq 'n') {
        #     az login
        # }    
    }
    else {
        # login
        az login
    }
    
    $subscriptionName = $(az account show --query "name"  --output tsv)
    $subscriptionId = $(az account show --query "id" --output tsv)

    Write-Information -MessageData "SubscriptionId: ${subscriptionId}"

    az account get-access-token --subscription $subscriptionId

    $Return.AKS_SUBSCRIPTION_NAME = "$subscriptionName"    
    $Return.AKS_SUBSCRIPTION_ID = "$subscriptionId"
    $Return.IS_CAFE_ENVIRONMENT = $($subscriptionName -match "CAFE" )
    return $Return
}

function global:SetCurrentAzureSubscription([Parameter(Mandatory = $true)][ValidateNotNull()][string] $subscriptionId) {

    #Create an hashtable variable 
    [hashtable]$Return = @{} 

    $currentsubscriptionName = $(az account show --query "name"  --output tsv)
    $currentsubscriptionId = $(az account show --query "id" --output tsv)

    Write-Information -MessageData "Current SubscriptionId: ${currentsubscriptionId}, newSubcriptionID: ${subscriptionId}"

    az account list --refresh

    if ($subscriptionId -eq $currentsubscriptionName -or ($subscriptionId -eq $currentsubscriptionId)) {
        # nothing to do
        Write-Information -MessageData "Subscription is already set properly so no need to anything"
    }
    else {
        Write-Information -MessageData "Setting subscription to $subscriptionId"
        az account set --subscription $subscriptionId
        $currentsubscriptionName = $(az account show --query "name"  --output tsv)
        $currentsubscriptionId = $(az account show --query "id" --output tsv)            
    }

    az account get-access-token --subscription $currentsubscriptionId

    return $Return
}
function global:GetCurrentAzureSubscription() {

    #Create an hashtable variable 
    [hashtable]$Return = @{} 

    $subscriptionName = $(az account show --query "name"  --output tsv)
    $subscriptionId = $(az account show --query "id" --output tsv)

    Write-Information -MessageData "Current SubscriptionId: ${subscriptionId}"

    $Return.AKS_SUBSCRIPTION_NAME = "$subscriptionName"    
    $Return.AKS_SUBSCRIPTION_ID = "$subscriptionId"
    $Return.IS_CAFE_ENVIRONMENT = $($subscriptionName -match "CAFE" )
    return $Return
}

function global:GetResourceGroupAndLocation([string] $defaultResourceGroup) {
    #Create an hashtable variable 
    [hashtable]$Return = @{} 

    Do { 
        $resourceGroup = Read-Host "Resource Group (leave empty for $defaultResourceGroup)"
        if ([string]::IsNullOrWhiteSpace($resourceGroup)) {
            $resourceGroup = $defaultResourceGroup
        }
    }
    while ([string]::IsNullOrWhiteSpace($resourceGroup))
    
    Write-Information -MessageData "Using resource group [$resourceGroup]"
    
    Write-Information -MessageData "checking if resource group already exists"
    $resourceGroupExists = az group exists --name ${resourceGroup}
    if ($resourceGroupExists -ne "true") {
        Do { $location = Read-Host "Location: (e.g., eastus)"}
        while ([string]::IsNullOrWhiteSpace($location))    

        Write-Information -MessageData "Create the Resource Group"
        az group create --name $resourceGroup --location $location --verbose
    }
    else {
        $location = az group show --name $resourceGroup --query "location" -o tsv
    }
    
    $Return.AKS_PERS_RESOURCE_GROUP = $resourceGroup
    $Return.AKS_PERS_LOCATION = $location

    #Return the hashtable
    Return $Return         

}

function global:CreateResourceGroupIfNotExists([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $location ) {
    [hashtable]$Return = @{} 

    Write-Information -MessageData "Using resource group [$resourceGroup]"
    
    Write-Information -MessageData "checking if resource group already exists"
    $resourceGroupExists = az group exists --name ${resourceGroup}
    if ($resourceGroupExists -ne "true") {
        Write-Information -MessageData "Create the Resource Group"
        az group create --name $resourceGroup --location $location --verbose
    }

    Return $Return         
}

function global:SetNetworkSecurityGroupRule([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $networkSecurityGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $rulename, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $ruledescription, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $sourceTag, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $port, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $priority ) {
    [hashtable]$Return = @{} 

    # the commands below don't like commas in $sourceTag so replace with space
    # https://docs.microsoft.com/en-us/cli/azure/network/nsg/rule?view=azure-cli-latest#az-network-nsg-rule-create
    # "Space-separated list of CIDR prefixes or IP ranges. Alternatively, specify ONE of 'VirtualNetwork', 'AzureLoadBalancer', 'Internet' or '*' to match all IPs."

    # we have to use @ splat operator here or az cli doesn't pick up strings with spaces properly
    if ([string]::IsNullOrWhiteSpace($(az network nsg rule show --name "$rulename" --nsg-name $networkSecurityGroup --resource-group $resourceGroup))) {
        Write-Information -MessageData "Creating rule: $rulename"
        az network nsg rule create -g $resourceGroup --nsg-name $networkSecurityGroup -n "$rulename" --priority $priority `
            --source-address-prefixes @($sourceTag.Split(",")) --source-port-ranges '*' `
            --destination-address-prefixes '*' --destination-port-ranges $port --access Allow `
            --protocol Tcp --description "$ruledescription" `
            --query "provisioningState" -o tsv
    }
    else {
        Write-Information -MessageData "Updating rule: $rulename"
        az network nsg rule update -g $resourceGroup --nsg-name $networkSecurityGroup -n "$rulename" --priority $priority `
            --source-address-prefixes @($sourceTag.Split(",")) --source-port-ranges '*' `
            --destination-address-prefixes '*' --destination-port-ranges $port --access Allow `
            --protocol Tcp --description "$ruledescription" `
            --query "provisioningState" -o tsv
  
    }
    return $Return
}
function global:DeleteNetworkSecurityGroupRule([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $networkSecurityGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $rulename ) {
    [hashtable]$Return = @{} 

    if (![string]::IsNullOrWhiteSpace($(az network nsg rule show --name "$rulename" --nsg-name $networkSecurityGroup --resource-group $resourceGroup))) {
        Write-Information -MessageData "Deleting $rulename rule"
        az network nsg rule delete -g $resourceGroup --nsg-name $networkSecurityGroup -n $rulename
    }   
    return $Return 
}

function global:DownloadKubectl([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $localFolder, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $version) {
    [hashtable]$Return = @{} 
    
    # download kubectl
    $kubeCtlFile = "$localFolder\kubectl.exe"
    $desiredKubeCtlVersion = "v${version}"
    $downloadkubectl = "n"
    if (!(Test-Path "$kubeCtlFile")) {
        $downloadkubectl = "y"
    }
    else {
        $kubectlversion = kubectl version --client=true --short=true
        Write-Information -MessageData "kubectl version: $kubectlversion"
        $kubectlversionMatches = $($kubectlversion -match "$desiredKubeCtlVersion")
        if (!$kubectlversionMatches) {
            $downloadkubectl = "y"
        }
    }
    if ( $downloadkubectl -eq "y") {
        $url = "https://storage.googleapis.com/kubernetes-release/release/${desiredKubeCtlVersion}/bin/windows/amd64/kubectl.exe"
        Write-Information -MessageData "Downloading kubectl.exe from url $url to $kubeCtlFile"

        If (Test-Path -Path "$kubeCtlFile") {
            Remove-Item -Path "$kubeCtlFile" -Force
        }
        
        DownloadFile -url $url -targetFile $kubeCtlFile
    }
    else {
        Write-Information -MessageData "kubectl already exists at $kubeCtlFile"    
    }
    return $Return
}

function global:DownloadFile([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $url, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $targetFile) {
    [hashtable]$Return = @{} 

    # https://learn-powershell.net/2013/02/08/powershell-and-events-object-events/
    $web = New-Object System.Net.WebClient
    $web.UseDefaultCredentials = $True
    $Index = $url.LastIndexOf("/")
    $file = $url.Substring($Index + 1)
    $newurl = $url.Substring(0, $index)
    #Some of the URLs have changed SSL versions - this should allow all SSL connections
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12
    Register-ObjectEvent -InputObject $web -EventName DownloadFileCompleted `
        -SourceIdentifier Web.DownloadFileCompleted -Action {    
        $Global:isDownloaded = $True
    }
    Register-ObjectEvent -InputObject $web -EventName DownloadProgressChanged `
        -SourceIdentifier Web.DownloadProgressChanged -Action {
        $Global:Data = $event
    }
    $web.DownloadFileAsync($url, ($targetFile -f $file))
    While (-Not $Global:isDownloaded) {
        $percent = $Global:Data.SourceArgs.ProgressPercentage
        $totalBytes = $Global:Data.SourceArgs.TotalBytesToReceive
        $receivedBytes = $Global:Data.SourceArgs.BytesReceived
        If ($percent -ne $null) {
            Write-Progress -Activity ("Downloading {0} from {1}" -f $file, $newurl) `
                -Status ("{0} bytes \ {1} bytes" -f $receivedBytes, $totalBytes)  -PercentComplete $percent
        }
    }
    Write-Progress -Activity ("Downloading {0} from {1}" -f $file, $newurl) `
        -Status ("{0} bytes \ {1} bytes" -f $receivedBytes, $totalBytes)  -Completed

    Unregister-Event -SourceIdentifier Web.DownloadFileCompleted
    Unregister-Event -SourceIdentifier Web.DownloadProgressChanged

    Write-Information -MessageData "Finished downloading $url"
    return $Return
    #endregion Download file from website    
}
function global:DownloadFileOld([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $url, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] $targetFile) {
    [hashtable]$Return = @{} 

    # from https://stackoverflow.com/questions/21422364/is-there-any-way-to-monitor-the-progress-of-a-download-using-a-webclient-object
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    # $request.Proxy = $null
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength() / 1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
    $buffer = new-object byte[] 4096KB
    Write-Information -MessageData "Buffer length: $($buffer.length)"
    $count = $responseStream.Read($buffer, 0, $buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0) {
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer, 0, $buffer.length)
        # Write-Information -MessageData "read: $count bytes"
        $downloadedBytes = $downloadedBytes + $count
        Write-Progress -activity "Downloading file '$($url.split('/') | Select-Object -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes / 1024)) / $totalLength) * 100)
        [System.Console]::CursorLeft = 0 
        [System.Console]::Write("Downloading '$($url.split('/') | Select-Object -Last 1)': {0}K of {1}K", [System.Math]::Floor($downloadedBytes / 1024), $totalLength) 
    }

    Write-Progress -activity "Finished downloading file '$($url.split('/') | Select-Object -Last 1)'"
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()

    return $Return
}

function global:FixLoadBalancerBackendPools([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $loadbalancer) {
    [hashtable]$Return = @{} 

    $loadbalancerBackendPoolName = $resourceGroup # the name may change in the future so we should look it up
    # for each worker VM
    $virtualmachines = az vm list -g $resourceGroup --query "[].name" -o tsv
    ForEach ($vm in $virtualmachines) {
        if ($vm -match "master" ) {}
        else {
            # for each worker VM
            Write-Information -MessageData "Checking VM: $vm"
            # get first nic
            # $nic = "k8s-linuxagent-14964077-nic-0"
            $nicId = $(az vm nic list -g $resourceGroup --vm-name $vm --query "[].id" -o tsv)
            $nic = $(az network nic show --ids $nicId --resource-group $resourceGroup --query "name" -o tsv)

            # get first ipconfig of nic
            $ipconfig = $(az network nic ip-config list --resource-group $resourceGroup --nic-name $nic --query "[?primary].name" -o tsv)

            $loadbalancerForNic = $(az network nic ip-config show --resource-group $resourceGroup --nic-name $nic --name $ipconfig --query "loadBalancerBackendAddressPools[].id" -o tsv)

            $foundNicInLoadbalancer = $false
            # if loadBalancerBackendAddressPools is missing then
            if ([string]::IsNullOrEmpty($loadbalancerForNic)) {
                Write-Warning "Fixing load balancer for vm: $vm by adding nic $nic with ip-config $ipconfig to backend pool $loadbalancerBackendPoolName in load balancer $loadbalancer "
                # --lb-address-pools: Space-separated list of names or IDs of load balancer address pools to associate with the NIC. If names are used, --lb-name must be specified.
                az network nic ip-config update --resource-group $resourceGroup --nic-name $nic --name $ipconfig --lb-name $loadbalancer --lb-address-pools $loadbalancerBackendPoolName
                $foundNicInLoadbalancer = $true
            }
            elseif ($($loadbalancerForNic -is [array])) {
                foreach ($lb in $loadbalancerForNic) {
                    Write-Information -MessageData "Checking loadbalancerforNic: $lb to see if it matches $loadbalancer"
                    if ($($lb -match $loadbalancer)) {
                        Write-Information -MessageData "Found loadbalancerforNic: $lb to match $loadbalancer"
                        $foundNicInLoadbalancer = $true
                    }
                }
            }
            elseif (($($loadbalancerForNic -contains $loadbalancer))) {
                $foundNicInLoadbalancer = $true
            }

            if (!$foundNicInLoadbalancer) {
                Write-Information -MessageData "nic is already bound to load balancer $loadbalancerForNic with ip-config $ipconfig"
                Write-Information -MessageData "adding internal load balancer to secondary ip-config"
                # get the first secondary ipconfig
                $ipconfig = $(az network nic ip-config list --resource-group $resourceGroup --nic-name $nic --query "[?!primary].name" -o tsv)[0]
                $loadbalancerForNic = $(az network nic ip-config show --resource-group $resourceGroup --nic-name $nic --name $ipconfig --query "loadBalancerBackendAddressPools[].id" -o tsv)
                if ([string]::IsNullOrEmpty($loadbalancerForNic)) {
                    Write-Warning "Fixing load balancer for vm: $vm by adding nic $nic with ip-config $ipconfig to backend pool $loadbalancerBackendPoolName in load balancer $loadbalancer "
                    # --lb-address-pools: Space-separated list of names or IDs of load balancer address pools to associate with the NIC. If names are used, --lb-name must be specified.
                    az network nic ip-config update --resource-group $resourceGroup --nic-name $nic --name $ipconfig --lb-name $loadbalancer --lb-address-pools $loadbalancerBackendPoolName
                }
                else {
                    Write-Information -MessageData "Load Balancer with ip-config $ipconfig is already setup properly for vm: $vm"
                }
            }
            else {
                Write-Information -MessageData "Load Balancer with ip-config $ipconfig is already setup properly for vm: $vm"
            }
        }
    }
    return $Return
}

function global:FixLoadBalancerBackendPorts([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $loadbalancer) {
    [hashtable]$Return = @{} 

    # 2. fix the ports in load balancing rules
    Write-Information -MessageData "Checking if the correct ports are setup in the load balancer"

    # get frontendip configs for this IP
    # $idToIPTuplesJson=$(az network lb frontend-ip list --resource-group=$AKS_PERS_RESOURCE_GROUP --lb-name $loadbalancer --query "[*].[id,privateIpAddress]")
    # $idToIPTuplesJson = $(az network lb frontend-ip list --resource-group=$AKS_PERS_RESOURCE_GROUP --lb-name $loadbalancer --query "[*].{id:id,ip:privateIpAddress}")
    $idToIPTuples = $(az network lb frontend-ip list --resource-group=$resourceGroup --lb-name $loadbalancer --query "[*].{id:id,ip:privateIpAddress}") | ConvertFrom-Json
    $services = $($(kubectl get services --all-namespaces -o json) | ConvertFrom-Json).items
    $loadBalancerServices = @()
    Write-Information -MessageData "---- Searching for kub services of type LoadBalancer"
    foreach ($service in $services) {
        if ($($service.spec.type -eq "LoadBalancer")) {
            if ($service.status.loadBalancer.ingress.Count -gt 0) {
                Write-Information -MessageData "Found kub services $($service.metadata.name) with $($service.status.loadBalancer.ingress[0].ip)"
                $loadBalancerServices += $service
            }
            else {
                Write-Information -MessageData "Found kub services $($service.metadata.name) but it has no ingress IP so skipping it"
            }
        }
    }
    Write-Information -MessageData "---- Finished searching for kub services of type LoadBalancer"

    ForEach ($tuple in $idToIPTuples) {
        Write-Information -MessageData "---------- tuple: $($tuple.ip)  $($tuple.id) ------------------"
        $rulesForIp = $(az network lb rule list --resource-group $resourceGroup --lb-name $loadbalancer --query "[?frontendIpConfiguration.id == '$($tuple.id)'].{frontid:frontendIpConfiguration.id,name:name,backendPort:backendPort,frontendPort: frontendPort}") | ConvertFrom-Json

        ForEach ($service in $loadBalancerServices) {
            Write-Information -MessageData "-------- Checking kub service: $($service.metadata.name) ----"
            # first check ports for internal loadbalancer
            $loadBalancerIp = $($service.status.loadBalancer.ingress[0].ip)
            # Write-Information -MessageData "Checking tuple ip $($tuple.ip) with loadBalancer Ip $loadBalancerIp"
            if ($tuple.ip -eq $loadBalancerIp) {
                #this is the right load balancer
                ForEach ($rule in $rulesForIp) {
                    Write-Information -MessageData "----- Checking rule $($rule.name) ----"
                    # Write-Information -MessageData "tuple $($tuple.ip) matches loadBalancerIP: $loadBalancerIp"
                    # match rule.backendPort to $loadbalancerInfo.spec.ports
                    ForEach ( $loadbalancerPortInfo in $($service.spec.ports)) {
                        # Write-Information -MessageData "Rule: $rule "
                        # Write-Information -MessageData "LoadBalancer:$loadbalancerPortInfo"
                        if ($($rule.frontendPort) -eq $($loadbalancerPortInfo.port)) {
                            Write-Information -MessageData "Found matching frontend ports: rule: $($rule.frontendPort) of rule $($rule.name) and loadbalancer: $($loadbalancerPortInfo.port) from $($loadbalancerPortInfo.name)"
                            if ($($rule.backendPort) -ne $($loadbalancerPortInfo.nodePort)) {
                                Write-Warning "Backend ports don't match.  Will change $($rule.backendPort) to $($loadbalancerPortInfo.nodePort)"
                                # set the rule backendPort to nodePort instead
                                $rule.backendPort = $loadbalancerPortInfo.nodePort
                                az network lb rule update --lb-name $loadbalancer --name $($rule.name) --resource-group $resourceGroup --backend-port $loadbalancerPortInfo.nodePort
                            }
                            else {
                                Write-Information -MessageData "Skipping changing backend port since it already matches $($rule.backendPort) vs $($loadbalancerPortInfo.nodePort)"
                            }
                        }
                        else {
                            Write-Information -MessageData "Skipping rule $($rule.name): Rule port: $($rule.backendPort) is not a match for loadbalancerPort $($loadbalancerPortInfo.port) from $($loadbalancerPortInfo.name)"                    
                        }
                    }
                }
                # get port from kubernetes service
            }
            else {
                Write-Information -MessageData "Skipping tuple since tuple ip $($tuple.ip) does not match loadBalancerIP: $loadBalancerIp"
            }
        }
        Write-Information -MessageData ""
    }
    return $Return
}

function global:FixLoadBalancers([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
    [hashtable]$Return = @{} 

    # hacks here to get around bugs in the acs-engine loadbalancer code
    Write-Information -MessageData "Checking if load balancers are setup correctly for resourceGroup: $resourceGroup"
    # 1. assign the nics to the loadbalancer

    # find loadbalancer with name 
    $loadbalancer = "${resourceGroup}-internal"

    $loadbalancerExists = $(az network lb show --name $loadbalancer --resource-group $resourceGroup --query "name" -o tsv)

    # if internal load balancer exists then fix it
    if ([string]::IsNullOrWhiteSpace($loadbalancerExists)) {
        Write-Information -MessageData "Loadbalancer $loadbalancer does not exist so no need to fix it"
        return
    }
    else {
        Write-Information -MessageData "loadbalancer $loadbalancer exists with name: $loadbalancerExists"
    }
    
    # this is not needed anymore since acs-engine fixed the bug 
    FixLoadBalancerBackendPools -resourceGroup $resourceGroup -loadbalancer $loadbalancer

    FixLoadBalancerBackendPorts -resourceGroup $resourceGroup -loadbalancer $loadbalancer

    return $Return
    # end hacks
}

function global:SetupDNS([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $dnsResourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $dnsrecordname, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $externalIP) {
    [hashtable]$Return = @{} 

    Write-Information -MessageData "Setting DNS zones"

    if ([string]::IsNullOrWhiteSpace($(az network dns zone show --name "$dnsrecordname" -g $dnsResourceGroup))) {
        Write-Information -MessageData "Creating DNS zone: $dnsrecordname"
        az network dns zone create --name "$dnsrecordname" -g $dnsResourceGroup
    }

    Write-Information -MessageData "Create A record for * in zone: $dnsrecordname"
    az network dns record-set a add-record --ipv4-address $externalIP --record-set-name "*" --resource-group $dnsResourceGroup --zone-name "$dnsrecordname"

    ShowNameServerEntries -dnsResourceGroup $dnsResourceGroup -dnsrecordname $dnsrecordname

    return $Return
}

function global:ShowNameServerEntries([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $dnsResourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $dnsrecordname) {
    [hashtable]$Return = @{} 

    # list out the name servers
    Write-Information -MessageData "Name servers to set in GoDaddy for *.$dnsrecordname"
    az network dns zone show -g $dnsResourceGroup -n "$dnsrecordname" --query "nameServers" -o tsv

    return $Return
}

function global:GetLoadBalancerIPs() {
    [hashtable]$Return = @{} 

    $startDate = Get-Date
    $timeoutInMinutes = 10
    $loadbalancer = "traefik-ingress-service-public"
    $loadbalancerInternal = "traefik-ingress-service-internal" 

    [int] $counter = 0
    Write-Information -MessageData "Waiting for IP to get assigned to the load balancer (Note: It can take upto 5 minutes for Azure to finish creating the load balancer)"
    Do { 
        $counter = $counter + 1
        $externalIP = $(kubectl get svc $loadbalancer -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}')
        if (!$externalIP) {
            Write-Information -MessageData "$counter"
            Start-Sleep -Seconds 10
        }
    }
    while ([string]::IsNullOrWhiteSpace($externalIP) -and ($startDate.AddMinutes($timeoutInMinutes) -gt (Get-Date)))
    Write-Information -MessageData "External IP: $externalIP"
    
    $counter = 0
    Write-Information -MessageData "Waiting for IP to get assigned to the internal load balancer (Note: It can take upto 5 minutes for Azure to finish creating the load balancer)"
    Do { 
        $counter = $counter + 1
        $internalIP = $(kubectl get svc $loadbalancerInternal -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}')
        if (!$internalIP) {
            Write-Information -MessageData "$counter"
            Start-Sleep -Seconds 10
        }
    }
    while ([string]::IsNullOrWhiteSpace($internalIP) -and ($startDate.AddMinutes($timeoutInMinutes) -gt (Get-Date)))
    Write-Information -MessageData "Internal IP: $internalIP"

    $Return.ExternalIP = $externalIP
    $Return.InternalIP = $internalIP
    
    return $Return
}
function global:CheckUrl([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $url, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $hostHeader) {

    [hashtable]$Return = @{} 

    $Request = [Net.HttpWebRequest]::Create($url)
    $Request.Host = $hostHeader
    $Response = $Request.GetResponse()

    $respstream = $Response.GetResponseStream(); 
    $sr = new-object System.IO.StreamReader $respstream; 
    $result = $sr.ReadToEnd(); 
    Write-Information -MessageData "$result"

    $Return.Response = $result
    $Return.StatusCode = $Response.StatusCode
    $Return.StatusDescription = $Response.StatusDescription
    return $Return
}
function global:GetDNSCommands() {

    [hashtable]$Return = @{} 

    $myCommands = @()

    # first get DNS entries for internal facing services
    $loadBalancerInternalIP = kubectl get svc traefik-ingress-service-internal -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}' --ignore-not-found=true

    if (![string]::IsNullOrEmpty($loadBalancerInternalIP)) {
        $internalDNSEntriesList = $(kubectl get ing --all-namespaces -l expose=internal -o jsonpath="{.items[*]..spec.rules[*].host}" --ignore-not-found=true)
        if ($internalDNSEntriesList) {
            $internalDNSEntries = $internalDNSEntriesList.Split(" ")
            ForEach ($dns in $internalDNSEntries) { 
                if ([string]::IsNullOrEmpty($loadBalancerInternalIP)) {
                    throw "loadBalancerInternalIP cannot be found"
                }
                $dnsWithoutDomain = $dns -replace ".healthcatalyst.net", ""
                $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recorddelete healthcatalyst.net $dnsWithoutDomain A /f"
                $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recordadd healthcatalyst.net $dnsWithoutDomain A $loadBalancerInternalIP"
                # these are reverse DNS entries that don't seem to be needed
                # $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recorddelete healthcatalyst.net $dns PTR /f"
                # $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recordadd 10.in-addr-arpa $loadBalancerInternalIP PTR $dns"
            }    
        }
        $customerid = ReadSecretValue -secretname customerid
        $customerid = $customerid.ToLower().Trim()

        $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recorddelete healthcatalyst.net $customerid A /f"
        $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recordadd healthcatalyst.net $customerid A $loadBalancerInternalIP"
    }

    # now get DNS entries for external facing services
    $loadBalancerIP = kubectl get svc traefik-ingress-service-public -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}' --ignore-not-found=true
    $externalDNSEntriesText = $(kubectl get ing --all-namespaces -l expose=external -o jsonpath="{.items[*]..spec.rules[*].host}" --ignore-not-found=true)
    
    if ($externalDNSEntriesText) {
        $externalDNSEntries = $externalDNSEntriesText.Split(" ")

        ForEach ($dns in $externalDNSEntries) { 
            if ($internalDNSEntries -and ($internalDNSEntries.Contains($dns))) {
                # already included in internal load balancer
            }
            else {
                if ([string]::IsNullOrEmpty($loadBalancerIP)) {
                    throw "loadBalancerIP cannot be found"
                }
                $dnsWithoutDomain = $dns -replace ".healthcatalyst.net", ""
                $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recorddelete healthcatalyst.net $dnsWithoutDomain A /f"
                $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recordadd healthcatalyst.net $dnsWithoutDomain A $loadBalancerIP"
                # $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recorddelete healthcatalyst.net $dns PTR /f"
                # $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recordadd 10.in-addr-arpa $loadBalancerIP PTR $dns"        
            }
        }
    }

    # now get DNS entries for any TCP load balancers
    $namespaces = $(kubectl get namespaces -o jsonpath="{.items[*].metadata.name}").Split(" ")
    foreach ($namespace in $namespaces) {
        # find services of type LoadBalancer
        $tcpLoadBalancers = $(kubectl get svc -n $namespace -o jsonpath="{.items[?(@.spec.type=='LoadBalancer')].metadata.name}" --ignore-not-found=true)
        if ($tcpLoadBalancers) {
            $tcpLoadBalancers = $tcpLoadBalancers.Split(" ")
            foreach ($tcpLoadBalancer in $tcpLoadBalancers) {
                $dns = $(kubectl get svc $tcpLoadBalancer -n $namespace -o jsonpath="{.metadata.labels.dns}" --ignore-not-found=true)
                if (![string]::IsNullOrEmpty($dns)) {
                    $loadBalancerTcpIP = kubectl get svc $tcpLoadBalancer -n $namespace -o jsonpath='{.status.loadBalancer.ingress[].ip}' --ignore-not-found=true
                    $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recorddelete healthcatalyst.net $dns.$customerid A /f"
                    $myCommands += "dnscmd cafeaddc-01.cafe.healthcatalyst.com /recordadd healthcatalyst.net $dns.$customerid A $loadBalancerTcpIP"    
                }
            }        
        }
    }    
    $Return.Commands = $myCommands
    return $Return
}
function global:WriteDNSCommands() {
    [hashtable]$Return = @{} 

    $myCommands = $(GetDNSCommands).Commands
    Write-Information -MessageData "To setup DNS entries in CAFE environment, remote desktop to CAFE DNS server: 10.5.2.4"
    Write-Information -MessageData "Open Powershell window As Administrator and paste the following:"
    ForEach ($myCommand in $myCommands) {
        Write-Information -MessageData $myCommand
    }
    Write-Information -MessageData ""
    return $Return
}

function global:GetPublicNameofMasterVM([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
    [hashtable]$Return = @{} 

    $resourceGroupLocation = az group show --name $resourceGroup --query "location" -o tsv

    $masterVMName = "${resourceGroup}.${resourceGroupLocation}.cloudapp.azure.com"

    $Return.Name = $masterVMName
    return $Return
}

function global:GetPrivateIPofMasterVM([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
    [hashtable]$Return = @{} 

    $virtualmachines = az vm list -g $resourceGroup --query "[?storageProfile.osDisk.osType != 'Windows'].name" -o tsv
    ForEach ($vm in $virtualmachines) {
        if ($vm -match "master" ) {
            $firstprivateip = az vm list-ip-addresses -g $resourceGroup -n $vm --query "[].virtualMachine.network.privateIpAddresses[0]" -o tsv
        }
    }

    $Return.PrivateIP = $firstprivateip
    return $Return
}

function global:CreateVM([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $vm, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subnetId, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $networkSecurityGroup, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $publicKeyFile, [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $image) {
    [hashtable]$Return = @{} 

    $publicIP = "${vm}PublicIP"
    Write-Information -MessageData "Creating public IP: $publicIP"
    $ip = az network public-ip create --name $publicIP `
        --resource-group $resourceGroup `
        --allocation-method Static --query "publicIp.ipAddress" -o tsv
    
    Write-Information -MessageData "Creating NIC: ${vm}-nic"
    az network nic create `
        --resource-group $resourceGroup `
        --name "${vm}-nic" `
        --subnet $subnetId `
        --network-security-group $networkSecurityGroup `
        --public-ip-address $publicIP `
        --query "provisioningState" -o tsv
    
    Write-Information -MessageData "Creating VM: ${vm} from image: $urn"
    az vm create --resource-group $resourceGroup --name $vm `
        --image "$image" `
        --size Standard_DS2_v2 `
        --admin-username azureuser --ssh-key-value $publicKeyFile `
        --nics "${vm}-nic"    
        
    $Return.IP = $ip
    return $Return                 
}

function global:TestConnection() {
    [hashtable]$Return = @{} 

    Write-Information -MessageData "Testing if we can connect to private IP Address: $privateIpOfMasterVM"
    # from https://stackoverflow.com/questions/11696944/powershell-v3-invoke-webrequest-https-error
    add-type 
    @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    $previousSecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    $previousSecurityPolicy = [System.Net.ServicePointManager]::CertificatePolicy
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    
    $canConnectToPrivateIP = $(Test-NetConnection $privateIpOfMasterVM -Port 443 -InformationLevel Quiet)
    
    if ($canConnectToPrivateIP -eq "True") {
        Write-Information -MessageData "Replacing master vm name, [$publicNameOfMasterVM], with private ip, [$privateIpOfMasterVM], in kube config file"
        (Get-Content "$kubeconfigjsonfile").replace("$publicNameOfMasterVM", "$privateIpOfMasterVM") | Set-Content "$kubeconfigjsonfile"
    }
    else {
        Write-Information -MessageData "Could not connect to private IP, [$privateIpOfMasterVM], so leaving the master VM name [$publicNameOfMasterVM] in the kubeconfig"
        $canConnectToMasterVM = $(Test-NetConnection $publicNameOfMasterVM -Port 443 -InformationLevel Quiet)
        if ($canConnectToMasterVM -ne "True") {
            Write-Error "Cannot connect to master VM: $publicNameOfMasterVM"
            Test-NetConnection $publicNameOfMasterVM -Port 443
        }
    }
    
    [System.Net.ServicePointManager]::CertificatePolicy = $previousSecurityPolicy
    [System.Net.ServicePointManager]::SecurityProtocol = $previousSecurityProtocol
        
    return $Return
}


function global:GetUrlAndIPForLoadBalancer([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {

    [hashtable]$Return = @{} 

    CheckUserIsLoggedIn   
    
    $subscriptionInfo = $(GetCurrentAzureSubscription)
    
    $IS_CAFE_ENVIRONMENT = $subscriptionInfo.IS_CAFE_ENVIRONMENT

    $loadBalancerIP = kubectl get svc traefik-ingress-service-public -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}' --ignore-not-found=true
    $loadBalancerInternalIP = kubectl get svc traefik-ingress-service-internal -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}'
    if ([string]::IsNullOrWhiteSpace($loadBalancerIP)) {
        $loadBalancerIP = $loadBalancerInternalIP
    }
    
    if ($IS_CAFE_ENVIRONMENT) {
        $customerid = ReadSecretValue -secretname customerid
        $customerid = $customerid.ToLower().Trim()
        $url = "dashboard.$customerid.healthcatalyst.net"
        $loadBalancerIP = $loadBalancerInternalIP
    }
    else {
        $url = $(GetPublicNameofMasterVM( $resourceGroup)).Name
    }


    $Return.IP = $loadBalancerIP
    $Return.Url = $url
    return $Return                 
}

function global:SetupWAF() {
    [hashtable]$Return = @{} 

    # not working yet

    # $nsgname = "IngressNSG"
    # $iprangetoallow = ""
    # if ([string]::IsNullOrEmpty($(az network nsg show --name "$nsgname" --resource-group "$AKS_PERS_RESOURCE_GROUP" ))) {
    #     az network nsg create --name "$nsgname" --resource-group "$AKS_PERS_RESOURCE_GROUP"
    # }

    # if ([string]::IsNullOrEmpty($(az network nsg rule show --nsg-name "$nsgname" --name "IPFilter" --resource-group "$AKS_PERS_RESOURCE_GROUP" ))) {
    #     # Rule priority, between 100 (highest priority) and 4096 (lowest priority). Must be unique for each rule in the collection.
    #     # Space-separated list of CIDR prefixes or IP ranges. Alternatively, specify ONE of 'VirtualNetwork', 'AzureLoadBalancer', 'Internet' or '*' to match all IPs.
    #     az network nsg rule create --name "IPFilter" `
    #         --nsg-name "$nsgname" `
    #         --priority 220 `
    #         --resource-group "$AKS_PERS_RESOURCE_GROUP" `
    #         --description "IP Filtering" `
    #         --access "Allow" `
    #         --source-address-prefixes "$iprangetoallow"
    # }

    # Write-Information -MessageData "Creating network security group to restrict IP address"

    Write-Information -MessageData "Setting up Azure Application Gateway"

    $gatewayName = "${customerid}Gateway"

    az network application-gateway show --name "$gatewayName" --resource-group "$AKS_PERS_RESOURCE_GROUP"
    $gatewayipName = "${gatewayName}PublicIP"

    Write-Information -MessageData "Checking if Application Gateway already exists"
    if ([string]::IsNullOrEmpty($(az network application-gateway show --name "$gatewayName" --resource-group "$AKS_PERS_RESOURCE_GROUP" ))) {

        # note application gateway provides no way to specify the resourceGroup of the vnet so we HAVE to create the App Gateway in the same resourceGroup
        # as the vnet and NOT in the resourceGroup of the cluster
        $gatewayip = az network public-ip show -g $AKS_PERS_RESOURCE_GROUP -n "$gatewayipName" --query "ipAddress" -o tsv;
        if ([string]::IsNullOrWhiteSpace($gatewayip)) {
            az network public-ip create -g $AKS_PERS_RESOURCE_GROUP -n "$gatewayipName" --location $AKS_PERS_LOCATION --allocation-method Dynamic

            # Write-Information -MessageData "Waiting for IP address to get assigned to $gatewayipName"
            # Do { 
            #     Start-Sleep -Seconds 10
            #     Write-Information -MessageData "."                
            #     $gatewayip = az network public-ip show -g $AKS_PERS_RESOURCE_GROUP -n "$gatewayipName" --query "ipAddress" -o tsv; 
            # }
            # while ([string]::IsNullOrWhiteSpace($gatewayip))
        }  
    
        # Write-Information -MessageData "Using Gateway IP: [$gatewayip]"

        $mysubnetid = "/subscriptions/${AKS_SUBSCRIPTION_ID}/resourceGroups/${AKS_SUBNET_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${AKS_VNET_NAME}/subnets/${AKS_SUBNET_NAME}"
            
        Write-Information -MessageData "Using subnet id: $mysubnetid"

        Write-Information -MessageData "Creating new application gateway with WAF (This can take 10-15 minutes)"
        # https://docs.microsoft.com/en-us/cli/azure/network/application-gateway?view=azure-cli-latest#az_network_application_gateway_create

        az network application-gateway create `
            --sku WAF_Medium `
            --name "$gatewayName" `
            --location "$AKS_PERS_LOCATION" `
            --resource-group "$AKS_PERS_RESOURCE_GROUP" `
            --vnet-name "$AKS_VNET_NAME" `
            --subnet "$mysubnetid" `
            --public-ip-address "$gatewayipName" `
            --servers "$EXTERNAL_IP"  `
    
        # https://docs.microsoft.com/en-us/azure/application-gateway/application-gateway-faq

        Write-Information -MessageData "Waiting for Azure Application Gateway to be created."
        az network application-gateway wait `
            --name "$gatewayName" `
            --resource-group "$AKS_PERS_RESOURCE_GROUP" `
            --created
    }
    else {

        # # set public IP
        $frontendPoolName = az network application-gateway show --name "$gatewayName" --resource-group "$AKS_SUBNET_RESOURCE_GROUP" --query "frontendIpConfigurations[0].name" -o tsv
        Write-Information -MessageData "Setting $gatewayipName as IP for frontend pool $frontendPoolName"
        az network application-gateway frontend-ip update `
            --gateway-name "$gatewayName" `
            --resource-group "$AKS_PERS_RESOURCE_GROUP" `
            --name "$frontendPoolName" `
            --public-ip-address "$gatewayipName"

        $backendPoolName = az network application-gateway show --name "$gatewayName" --resource-group "$AKS_SUBNET_RESOURCE_GROUP" --query "backendAddressPools[0].name" -o tsv
        Write-Information -MessageData "Setting $EXTERNAL_IP as IP for backend pool $backendPoolName"
        # set backend private IP
        az network application-gateway address-pool update  `
            --gateway-name "$gatewayName" `
            --resource-group "$AKS_PERS_RESOURCE_GROUP" `
            --name "$backendPoolName" `
            --servers "$EXTERNAL_IP"

        az network application-gateway wait `
            --name "$gatewayName" `
            --resource-group "$AKS_PERS_RESOURCE_GROUP" `
            --updated            
    }

    if ($(az network application-gateway waf-config show --gateway-name "$gatewayName" --resource-group "$AKS_PERS_RESOURCE_GROUP" --query "firewallMode" -o tsv) -eq "Prevention") {
    }
    else {
        Write-Information -MessageData "Enabling Prevention mode of firewall"
        az network application-gateway waf-config set `
            --enabled true `
            --firewall-mode Prevention `
            --gateway-name "$gatewayName" `
            --resource-group "$AKS_PERS_RESOURCE_GROUP" `
            --rule-set-type "OWASP" `
            --rule-set-version "3.0"            
    }
    
    # if ([string]::IsNullOrEmpty($(az network application-gateway probe show --gateway-name "$gatewayName" --name "MyCustomProbe" --resource-group "$AKS_SUBNET_RESOURCE_GROUP"))) {
    #     # create a custom probe
    #     az network application-gateway probe create --gateway-name "$gatewayName" `
    #         --resource-group "$AKS_SUBNET_RESOURCE_GROUP" `
    #         --name "MyCustomProbe" `
    #         --path "/" `
    #         --protocol "Http" `
    #         --host "dashboard.${dnsrecordname}"

    #     # associate custom probe with HttpSettings: appGatewayBackendHttpSettings
    #     az network application-gateway http-settings update --gateway-name "$gatewayName" `
    #         --name "appGatewayBackendHttpSettings" `
    #         --resource-group "$AKS_SUBNET_RESOURCE_GROUP" `
    #         --probe "MyCustomProbe" `
    #         --enable-probe true `
    #         --host-name "dashboard.${dnsrecordname}"
    # }


    Write-Information -MessageData "Checking for health of backend pool"
    az network application-gateway show-backend-health `
        --name "$gatewayName" `
        --resource-group "$AKS_PERS_RESOURCE_GROUP" `
        --query "backendAddressPools[0].backendHttpSettingsCollection[0].servers[0].health"

    # set EXTERNAL_IP to be the IP of the Application Gateway
    $EXTERNAL_IP = az network public-ip show -g $AKS_PERS_RESOURCE_GROUP -n "$gatewayipName" --query "ipAddress" -o tsv;

    return $Return
}
function global:ConfigureWAF() {
    [hashtable]$Return = @{} 

    # not working yet
    $publicip = az network public-ip show -g $AKS_PERS_RESOURCE_GROUP -n IngressPublicIP --query "ipAddress" -o tsv;
    if ([string]::IsNullOrWhiteSpace($publicip)) {
        az network public-ip create -g $AKS_PERS_RESOURCE_GROUP -n IngressPublicIP --location $AKS_PERS_LOCATION --allocation-method Static
        $publicip = az network public-ip show -g $AKS_PERS_RESOURCE_GROUP -n IngressPublicIP --query "ipAddress" -o tsv;
    }  

    Write-Information -MessageData "Using Public IP: [$publicip]"
    # get vnet and subnet name
    Do { $confirmation = Read-Host "Would you like to connect the Azure WAF to an existing virtual network? (y/n)"}
    while ([string]::IsNullOrWhiteSpace($confirmation))

    if ($confirmation -eq 'y') {
        Write-Information -MessageData "Finding existing vnets..."
        # az network vnet list --query "[].[name,resourceGroup ]" -o tsv    

        $vnets = az network vnet list --query "[].[name]" -o tsv

        Do { 
            Write-Host "------  Existing vnets -------"
            for ($i = 1; $i -le $vnets.count; $i++) {
                Write-Host "$i. $($vnets[$i-1])"
            }    
            Write-Host "------  End vnets -------"

            $index = Read-Host "Enter number of vnet to use (1 - $($vnets.count))"
            $AKS_VNET_NAME = $($vnets[$index - 1])
        }
        while ([string]::IsNullOrWhiteSpace($AKS_VNET_NAME))    

        if ("$AKS_VNET_NAME") {
        
            # Do { $AKS_SUBNET_RESOURCE_GROUP = Read-Host "Resource Group of Virtual Network"}
            # while ([string]::IsNullOrWhiteSpace($AKS_SUBNET_RESOURCE_GROUP)) 

            $AKS_SUBNET_RESOURCE_GROUP = az network vnet list --query "[?name == '$AKS_VNET_NAME'].resourceGroup" -o tsv
            Write-Information -MessageData "Using subnet resource group: [$AKS_SUBNET_RESOURCE_GROUP]"

            Write-Information -MessageData "Finding existing subnets in $AKS_VNET_NAME ..."
            $subnets = az network vnet subnet list --resource-group $AKS_SUBNET_RESOURCE_GROUP --vnet-name $AKS_VNET_NAME --query "[].name" -o tsv
        
            Do { 
                Write-Host "------  Subnets in $AKS_VNET_NAME -------"
                for ($i = 1; $i -le $subnets.count; $i++) {
                    Write-Host "$i. $($subnets[$i-1])"
                }    
                Write-Host "------  End Subnets -------"

                Write-Host "NOTE: Each customer should have their own gateway subnet.  This subnet should be different than the cluster subnet"
                $index = Read-Host "Enter number of subnet to use (1 - $($subnets.count))"
                $AKS_SUBNET_NAME = $($subnets[$index - 1])
            }
            while ([string]::IsNullOrWhiteSpace($AKS_SUBNET_NAME)) 

        }
    }  
    return $Return
}

function global:GetConfigFile() {

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
    return $Return
}

function global:ReadConfigFile() {
    [hashtable]$Return = @{} 

    $configfilepath = $(GetConfigFile).FilePath

    Write-Information -MessageData "Reading config from $configfilepath"
    $config = $(Get-Content $configfilepath -Raw | ConvertFrom-Json)

    $Return.Config = $config
    return $Return
}

function global:SaveConfigFile() {
    [hashtable]$Return = @{} 

    New-Item -ItemType Directory -Force -Path $folder

    return $Return
}

function global:GetResourceGroup() {
    [hashtable]$Return = @{} 
    $Return.ResourceGroup = ReadSecretData -secretname azure-secret -valueName "resourcegroup"    

    return $Return
}
function global:CreateAzureStorage([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace) {
    [hashtable]$Return = @{} 

    if ([string]::IsNullOrWhiteSpace($namespace)) {
        Write-Error "no parameter passed to CreateAzureStorage"
        exit
    }
    
    $resourceGroup = $(GetResourceGroup).ResourceGroup

    Write-Information -MessageData "Using resource group: $resourceGroup"        
    
    if ([string]::IsNullOrWhiteSpace($(kubectl get namespace $namespace --ignore-not-found=true))) {
        kubectl create namespace $namespace
    }
    
    $shareName = "$namespace"

    CreateShare -resourceGroup $resourceGroup -sharename $shareName -deleteExisting $false
    CreateShare -resourceGroup $resourceGroup -sharename "${shareName}backups" -deleteExisting $false

    return $Return
}
function global:DeleteAzureStorage([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace) {
    [hashtable]$Return = @{} 

    if ([string]::IsNullOrWhiteSpace($namespace)) {
        Write-Error "no parameter passed to DeleteAzureStorage"
        exit
    }
    
    $resourceGroup = $(GetResourceGroup).ResourceGroup

    Write-Information -MessageData "Using resource group: $resourceGroup"        
    
    $shareName = "$namespace"
    $storageAccountName = ReadSecretData -secretname azure-secret -valueName "azurestorageaccountname" 
    
    $storageAccountConnectionString = az storage account show-connection-string -n $storageAccountName -g $resourceGroup -o tsv
    
    Write-Information -MessageData "deleting the file share: $shareName"
    DeleteAzureFileShare -sharename $sharename -storageAccountConnectionString $storageAccountConnectionString
    return $Return
}

function global:CreateOnPremStorage([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace) {
    [hashtable]$Return = @{} 

    if ([string]::IsNullOrWhiteSpace($namespace)) {
        Write-Error "no parameter passed to CreateOnPremStorage"
        exit
    }
    
   
    $shareName = "$namespace"
    $sharePath = "/mnt/data/$shareName"

    Write-Information -MessageData "Create the file share: $sharePath"

    New-Item -ItemType Directory -Force -Path $sharePath   
    New-Item -ItemType Directory -Force -Path "${sharePath}backups"

    return $Return
}
function global:DeleteOnPremStorage([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace) {
    [hashtable]$Return = @{} 

    if ([string]::IsNullOrWhiteSpace($namespace)) {
        Write-Error "no parameter passed to DeleteOnPremStorage"
        exit
    }
    
   
    $shareName = "$namespace"
    $sharePath = "/mnt/data/$shareName"

    Write-Information -MessageData "Deleting the file share: $sharePath"

    Remove-Item -Recurse -Force $sharePath 
    
    return $Return
}

function global:WaitForLoadBalancers([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
    [hashtable]$Return = @{} 

    $loadBalancerIP = kubectl get svc traefik-ingress-service-public -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}' --ignore-not-found=true
    if ([string]::IsNullOrWhiteSpace($loadBalancerIP)) {
        $loadBalancerIP = kubectl get svc traefik-ingress-service-internal -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}'
    }
    $loadBalancerInternalIP = kubectl get svc traefik-ingress-service-internal -n kube-system -o jsonpath='{.status.loadBalancer.ingress[].ip}' --ignore-not-found=true
    
    Write-Information -MessageData "Sleeping for 10 seconds so kube services get IPs assigned"
    Start-Sleep -Seconds 10
    
    # if($($config.ingress.fixloadbalancer)){
    #     FixLoadBalancers -resourceGroup $AKS_PERS_RESOURCE_GROUP
    # }    
    # FixLoadBalancers -resourceGroup $resourceGroup
    
    return $Return
}

function global:InstallStack([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $baseUrl, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $appfolder, `
        $isAzure, `
        [string]$externalIp, `
        [string]$internalIp, `
        [string]$externalSubnetName, `
        [string]$internalSubnetName, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][bool] $local) {
    [hashtable]$Return = @{} 

    if ($isAzure) {
        CheckUserIsLoggedIn
    }
    
    if ($namespace -ne "kube-system") {
        if ($isAzure) {
            CreateAzureStorage -namespace $namespace
        }
        else {
            CreateOnPremStorage -namespace $namespace    
        }
    }

    $configpath = "$baseUrl/${appfolder}/index.json"
    Write-Information -MessageData "Loading stack manifest from $configpath"
    
    if ($baseUrl.StartsWith("http")) { 
        $config = $(Invoke-WebRequest -useb $configpath | ConvertFrom-Json)
    }
    else {
        $config = $(Get-Content -Path $configpath -Raw | ConvertFrom-Json)
    }

    LoadStack -namespace $namespace -baseUrl $baseUrl -appfolder "$appfolder" `
        -config $config `
        -isAzure $isAzure `
        -externalIp $externalIp -internalIp $internalIp `
        -externalSubnetName $externalSubnetName -internalSubnetName $internalSubnetName `
        -local $local
    
    if ($isAzure) {
        WaitForLoadBalancers -resourceGroup $(GetResourceGroup).ResourceGroup
    }
    
    # open ports specified
    if ($(HasProperty -object $($config) "ports")) {
        Write-Information -MessageData "Opening ports"
        if ($isAzure) {
            $resourceGroup = $(GetResourceGroup).ResourceGroup
            foreach ($portEntry in $config.ports) {
                OpenPortInAzure -resourceGroup $resourceGroup -port $portEntry.port -name $portEntry.name -protocol $portEntry.protocol -type $portEntry.type
            }
        }
        else {
            foreach ($portEntry in $config.ports) {
                OpenPortOnPrem -port $portEntry.port -name $portEntry.name -protocol $portEntry.protocol -type $portEntry.type
            }
        }
    }

    if ($isAzure) {
        $resourceGroup = $(GetResourceGroup).ResourceGroup
        WaitForLoadBalancersToGetIPs -namespace $namespace
        MovePortsToLoadBalancerForNamespace -resourceGroup $resourceGroup -namespace $namespace
    }
    return $Return
}


function global:DeleteNamespaceAndData([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace, $isAzure) {
    [hashtable]$Return = @{} 

    CleanOutNamespace -namespace $namespace
    if ($isAzure) {
        DeleteAzureStorage -namespace $namespace
    }
    else {
        DeleteOnPremStorage -namespace $namespace
    }

    DeleteAllSecrets -namespace $namespace

    return $Return
}

function global:MoveInternalLoadBalancerToIP([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subscriptionId, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subnetResourceGroup, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $vnetName, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $subnetName, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $newIpAddress) {
    
    [hashtable]$Return = @{} 

    # find loadbalancer with name 
    $loadbalancer = "${resourceGroup}-internal"
    Write-Information -MessageData "Moving load balancer $loadbalancer to private Ip $newIpAddress"

    $loadbalancerExists = $(az network lb show --name $loadbalancer --resource-group $resourceGroup --query "name" -o tsv)

    if ([string]::IsNullOrWhiteSpace($loadbalancerExists)) {
        Write-Information -MessageData "Loadbalancer $loadbalancer does not exist so no need to move it"
        return
    }
    else {
        Write-Information -MessageData "loadbalancer $loadbalancer exists with name: $loadbalancerExists"
    }

    $frontendlist = $(az network lb frontend-ip list -g $resourceGroup --lb-name $loadbalancer --query "[].name" -o tsv)

    $mysubnetid = $(GetSubnetId -subscriptionId $subscriptionId -subnetResourceGroup $subnetResourceGroup -vnetName $vnetName -subnetName $subnetName).SubnetId

    if ($frontendlist) {
        $frontends = $frontendlist.Split(" ");
        foreach ($frontend in $frontends) {
            $currentPrivateIpAddress = $(az network lb frontend-ip show -g $resourceGroup --lb-name $loadbalancer -n $frontend --query "privateIpAddress" -o tsv)
            if ($currentPrivateIpAddress -ne $newIpAddress) {
                Write-Information -MessageData "Setting frontend ip [$frontend] of internal loadbalancer [$loadbalancer] from [$currentPrivateIpAddress] to privateIP: [$newIpAddress]"
                az network lb frontend-ip update -g $resourceGroup --lb-name $loadbalancer -n $frontend --subnet $mysubnetid --private-ip-address $newIpAddress            
            }
            else {
                Write-Information -MessageData "internal loadbalancer already set to privateIP: [$newIpAddress]"                
            }
        }

        return $Return
    }
}

function global:MovePortsToLoadBalancer([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup) {
    [hashtable]$Return = @{} 

    $namespaces = $(kubectl get namespaces -o jsonpath="{.items[*].metadata.name}").Split(" ")

    foreach ($namespace in $namespaces) {
        MovePortsToLoadBalancerForNamespace -resourceGroup $resourceGroup -namespace $namespace
    }

    return $Return
}

function global:MovePortsToLoadBalancerForNamespace([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $resourceGroup, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace) {
    [hashtable]$Return = @{} 

    Write-Information -MessageData "Checking if load balancers are setup correctly for resourceGroup: $resourceGroup in namespace: $namespace"
    # 1. assign the nics to the loadbalancer

    # find loadbalancer with name 
    $loadbalancer = "${resourceGroup}-internal"

    $loadbalancerExists = $(az network lb show --name $loadbalancer --resource-group $resourceGroup --query "name" -o tsv)

    # if internal load balancer exists then fix it
    if ([string]::IsNullOrWhiteSpace($loadbalancerExists)) {
        Write-Information -MessageData "Loadbalancer $loadbalancer does not exist so no need to fix it"
        return
    }
    else {
        Write-Information -MessageData "loadbalancer $loadbalancer exists with name: $loadbalancerExists"
    }

    $loadbalancerInfo = $(GetLoadBalancerIPs)
    $loadbalanceripAddress = $loadbalancerInfo.InternalIP

    if ($loadbalanceripAddress) {
        $expose = "internal"
        Write-Information -MessageData "Checking ports for $expose load balancer"
    
        AddPortsToLoadBalancerForNamespace -namespace $namespace -expose $expose -loadbalanceripAddress $loadbalanceripAddress
    }

    $loadbalanceripAddress = $loadbalancerInfo.ExternalIP
    if ($loadbalanceripAddress) {

        $expose = "external"
        Write-Information -MessageData "Checking ports for $expose load balancer"

        AddPortsToLoadBalancerForNamespace -namespace $namespace -expose $expose -loadbalanceripAddress $loadbalanceripAddress
    }
    
    return $Return
}

function global:WaitForLoadBalancersToGetIPs([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace) {

    $servicesastext = $(kubectl get svc -n $namespace -o jsonpath="{.items[?(@.spec.type == 'LoadBalancer')].metadata.name}")

    if ($servicesastext) {
        $services = $servicesastext.Split(" ")
        Write-Information -MessageData "Waiting for services to get IP: $servicesastext"
        Do {       
            $servicesMissingIp = @()
            $servicesMissingIpText = ""
            foreach ($service in $services) {
                $loadBalancerIP = kubectl get svc $service -n $namespace -o jsonpath='{.status.loadBalancer.ingress[].ip}' --ignore-not-found=true
                if (!$loadBalancerIP) {
                    $servicesMissingIp += $service
                    $servicesMissingIpText = $servicesMissingIpText + " $service"
                }
            }
            $services = $servicesMissingIp
            if ($servicesMissingIpText) {
                Write-Information -MessageData "Waiting for services to get IP: $servicesMissingIpText"
                Start-Sleep -Seconds 10
            }
        }
        while ($services.Count -ne 0)  
    }
}
function global:AddPortsToLoadBalancerForNamespace([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $namespace, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $expose, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $loadbalanceripAddress) {
    Write-Information -MessageData "Checking ports in namespace: $namespace"
    $servicesastext = $(kubectl get svc -n $namespace -o jsonpath="{.items[?(@.metadata.labels.expose == '$expose')].metadata.name}" --ignore-not-found=true)

    if ($servicesastext) {
        foreach ($service in $servicesastext.Split(" ")) {
            Write-Information -MessageData "Checking service $service"
            $portsastext = $(kubectl get svc $service -n $namespace -o jsonpath="{.spec.ports[0].port}")
            $nodePortsastext = $(kubectl get svc $service -n $namespace -o jsonpath="{.spec.ports[0].nodePort}")
            if ($portsastext) {
                $ports = $portsastext.Split(" ")
                $nodePorts = $nodePortsastext.Split(" ")
                $nodePort = $nodePorts[0]

                foreach ($port in $ports) {
                    AddPortToLoadBalancer -loadbalanceripAddress $loadbalanceripAddress -frontendport $port -backendport $nodePort 
                }
            }
        }
    }
}
function global:AddPortToLoadBalancer([Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $loadbalanceripAddress, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $frontendport, `
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $backendport) {
    [hashtable]$Return = @{} 

    $frontendipname = $(az network lb frontend-ip list --resource-group=$resourceGroup --lb-name $loadbalancer --query "[?privateIpAddress=='$loadbalanceripAddress'].name" -o tsv)

    $backendpool = "$resourceGroup"

    # $query = '[?frontendPort == `' + $frontendport + '`].name'
    # $rulename = $(az network lb rule list --lb-name $loadbalancer --resource-group $resourceGroup --query $query -o tsv)

    # delete previous rule
    # az network lb rule update --lb-name $loadbalancer --name $rulename --resource-group $resourceGroup --frontend-ip-name $frontendipname

    # $query = '[?frontendPort == `' + $frontendport + '`].probe.id'
    # $probeid = $(az network lb rule list --lb-name $loadbalancer --resource-group $resourceGroup --query $query -o tsv)

    # $query = '[?id==`' + $probeid + '`].port'
    # $backendport = $(az network lb probe list -g $resourceGroup --lb-name $loadbalancer --query $query -o tsv)

    if (!$backendport) {
        throw "no backend port found for frontendport $frontendport in load balancer $loadbalancer"
    }
    # $query = '[?id==`' + $probeid + '`].name'
    # $probename=$(az network lb probe list -g $resourceGroup --lb-name $loadbalancer --query $query -o tsv)
    
    # create a new probe
    $rulename = "hcrule$frontendport"
    $probename = "hcprobe$frontendport"

    # delete old rules and probes
    if ($(az network lb rule list --lb-name $loadbalancer --resource-group $resourceGroup --query "[?name=='$rulename'].name" -o tsv)) {
        Write-Information -MessageData "Deleting old rule: $rulename"
        az network lb rule delete --lb-name $loadbalancer --resource-group $resourceGroup --name $rulename
    }

    if ($(az network lb probe list --lb-name $loadbalancer --resource-group $resourceGroup --query "[?name=='$probename'].name" -o tsv)) {
        Write-Information -MessageData "Deleting old probe: $probename"
        az network lb probe delete --lb-name $loadbalancer --resource-group $resourceGroup --name $probename
    }

    if (!$(az network lb probe list --lb-name $loadbalancer --resource-group $resourceGroup --query "[?name=='$probename'].name" -o tsv)) {
        Write-Information -MessageData "Creating Probe: $probename with backendport: $backendport"
        az network lb probe create --lb-name $loadbalancer --resource-group $resourceGroup `
            --name $probename `
            --port $backendport `
            --protocol Tcp 
    }
    else {
        Write-Information -MessageData "Probe: $probename already exists"
    }
    
    if (!$(az network lb rule list --lb-name $loadbalancer --resource-group $resourceGroup --query "[?name=='$rulename'].name" -o tsv)) {
        Write-Information -MessageData "Creating rule: $rulename with frontendport: $frontendport backendport: $backendport"
        az network lb rule create --lb-name $loadbalancer --resource-group $resourceGroup --name $rulename --protocol Tcp `
            --backend-port $backendport --frontend-port $frontendport `
            --frontend-ip-name $frontendipname --backend-pool-name $backendpool `
            --probe-name $probename
    }
    else {
        Write-Information -MessageData "Rule: $rulename already exists"        
    }

    # name
    # frontend-ip-name
    # port 3307
    # backendport from health probe
    # backend pool
    # health probe

    # az network lb frontend-ip delete --lb-name $loadbalancer --name "afc6ca56f652011e8878b000d3a3225e-default" --resource-group $resourceGroup

    return $Return
}

#-------------------
Write-Information -MessageData "end common.ps1 version $versioncommon"
