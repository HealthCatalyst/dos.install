<#
  .SYNOPSIS
  GetStorageAccountName
  
  .DESCRIPTION
  GetStorageAccountName
  
  .INPUTS
  GetStorageAccountName - The name of GetStorageAccountName

  .OUTPUTS
  None
  
  .EXAMPLE
  GetStorageAccountName

  .EXAMPLE
  GetStorageAccountName


#>
function GetStorageAccountName() {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [parameter (Mandatory = $true) ]
        [ValidateNotNullOrEmpty()]
        [string] 
        $resourceGroup
    )

    Write-Verbose 'GetStorageAccountName: Starting'

    [hashtable]$Return = @{} 

    [string] $storageAccountName = "${resourceGroup}storage"
    # remove non-alphanumeric characters and use lowercase since azure doesn't allow those in a storage account
    $storageAccountName = $storageAccountName -replace '[^a-zA-Z0-9]', ''
    $storageAccountName = $storageAccountName.ToLower()
    if ($storageAccountName.Length -gt 24) {
        $storageAccountName = $storageAccountName.Substring(0, 24) # azure does not allow names longer than 24
    }

    $Return.StorageAccountName = $storageAccountName

    Write-Verbose 'GetStorageAccountName: Done'

    return $Return
}

Export-ModuleMember -Function "GetStorageAccountName"