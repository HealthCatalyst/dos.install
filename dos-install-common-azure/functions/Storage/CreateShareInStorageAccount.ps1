<#
  .SYNOPSIS
  CreateShareInStorageAccount

  .DESCRIPTION
  CreateShareInStorageAccount

  .INPUTS
  CreateShareInStorageAccount - The name of CreateShareInStorageAccount

  .OUTPUTS
  None

  .EXAMPLE
  CreateShareInStorageAccount

  .EXAMPLE
  CreateShareInStorageAccount


#>
function CreateShareInStorageAccount() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $storageAccountName
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $resourceGroup
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $sharename
        ,
        $deleteExisting
    )
    Write-Verbose 'CreateShareInStorageAccount: Starting'

    [hashtable]$Return = @{}

    [int]$filesharesize = 128

    $storageAccountConnectionString = az storage account show-connection-string -n $storageAccountName -g $resourceGroup -o tsv

    # Write-Information -MessageData "Storage connection string: $storageAccountConnectionString"

    if ($deleteExisting) {
        DeleteShare -sharename $sharename -storageAccountConnectionString $storageAccountConnectionString
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

    Write-Verbose 'CreateShareInStorageAccount: Done'
}

Export-ModuleMember -Function "CreateShareInStorageAccount"