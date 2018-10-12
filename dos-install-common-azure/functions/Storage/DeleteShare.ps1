<#
  .SYNOPSIS
  DeleteShare

  .DESCRIPTION
  DeleteShare

  .INPUTS
  DeleteShare - The name of DeleteShare

  .OUTPUTS
  None

  .EXAMPLE
  DeleteShare

  .EXAMPLE
  DeleteShare


#>
function DeleteShare() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $sharename
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $storageAccountConnectionString
    )

    Write-Verbose 'DeleteShare: Starting'

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

    Write-Verbose 'DeleteShare: Done'

    return $Return
}

Export-ModuleMember -Function "DeleteShare"