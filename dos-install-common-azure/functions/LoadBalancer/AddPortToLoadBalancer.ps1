<#
.SYNOPSIS
AddPortToLoadBalancer

.DESCRIPTION
AddPortToLoadBalancer

.INPUTS
AddPortToLoadBalancer - The name of AddPortToLoadBalancer

.OUTPUTS
None

.EXAMPLE
AddPortToLoadBalancer

.EXAMPLE
AddPortToLoadBalancer


#>
function AddPortToLoadBalancer() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $loadbalanceripAddress,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $frontendport,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $backendport
    )

    Write-Verbose 'AddPortToLoadBalancer: Starting'
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


    Write-Verbose 'AddPortToLoadBalancer: Done'
    return $Return

}

Export-ModuleMember -Function 'AddPortToLoadBalancer'