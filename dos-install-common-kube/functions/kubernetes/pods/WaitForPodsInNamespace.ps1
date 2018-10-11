<#
  .SYNOPSIS
  WaitForPodsInNamespace
  
  .DESCRIPTION
  WaitForPodsInNamespace
  
  .INPUTS
  WaitForPodsInNamespace - The name of WaitForPodsInNamespace

  .OUTPUTS
  None
  
  .EXAMPLE
  WaitForPodsInNamespace

  .EXAMPLE
  WaitForPodsInNamespace


#>
function WaitForPodsInNamespace() {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $namespace
        , 
        [Parameter(Mandatory = $true)]
        [int]
        $interval
    )

    Write-Verbose 'WaitForPodsInNamespace: Starting'

    [hashtable]$Return = @{} 

    $pods = $(kubectl get pods -n $namespace -o jsonpath='{.items[*].metadata.name}')
    [string] $waitingonPodText = "n"

    $counter = 0
    Do {
        $waitingonPodText = ""
        Write-Information -MessageData "---- waiting until all pods are running in namespace $namespace ---"

        Start-Sleep -Seconds $interval
        $counter++
        [string] $pods = $(kubectl get pods -n $namespace -o jsonpath='{.items[*].metadata.name}')

        if (!$pods) {
            throw "No pods were found in namespace $namespace"
        }

        foreach ($pod in $pods.Split(" ")) {
            [string] $podstatus = $(kubectl get pods $pod -n $namespace -o jsonpath='{.status.phase}')
            if ($podstatus -eq "Running") {
                # nothing to do
            }
            elseif ($podstatus -eq "Pending") {
                # Write-Information -MessageData "${pod}: $podstatus"
                [string] $containerReady = $(kubectl get pods $pod -n $namespace -o jsonpath="{.status.containerStatuses[0].ready}")
                if ($containerReady -ne "true" ) {
                    [string] $containerStatus = $(kubectl get pods $pod -n $namespace -o jsonpath="{.status.containerStatuses[0].state.waiting.reason}")
                    if (![string]::IsNullOrEmpty(($containerStatus))) {
                        $waitingonPodText = "${waitingonPodText}${pod}($containerStatus);"    
                    }
                    else {
                        $waitingonPodText = "${waitingonPodText}${pod}(container);"                        
                    }
                    # Write-Information -MessageData "container in $pod is not ready yet: $containerReady"
                }
            }
            else {
                $waitingonPodText = "${waitingonPodText}${pod}($podstatus);" 
            }
        }
            
        Write-Information -MessageData "[$counter] $waitingonPodText"
    }
    while (![string]::IsNullOrEmpty($waitingonPodText) -and ($counter -lt 30) )

    kubectl get pods -n $namespace -o wide

    if ($counter -gt 29) {
        Write-Information -MessageData "--- warnings in kubenetes event log ---"
        kubectl get events -n $namespace | grep "Warning" | tail    
    } 

    Write-Verbose 'WaitForPodsInNamespace: Done'
    return $Return    

}

Export-ModuleMember -Function "WaitForPodsInNamespace"