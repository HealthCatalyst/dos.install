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
        $interval
    )

    Write-Verbose 'WaitForPodsInNamespace: Starting'

    [hashtable]$Return = @{} 

    $pods = $(kubectl get pods -n $namespace -o jsonpath='{.items[*].metadata.name}')
    $waitingonPod = "n"

    $counter = 0
    Do {
        $waitingonPod = ""
        Write-Information -MessageData "---- waiting until all pods are running in namespace $namespace ---"

        Start-Sleep -Seconds $interval
        $counter++
        $pods = $(kubectl get pods -n $namespace -o jsonpath='{.items[*].metadata.name}')

        if (!$pods) {
            throw "No pods were found in namespace $namespace"
        }

        foreach ($pod in $pods.Split(" ")) {
            $podstatus = $(kubectl get pods $pod -n $namespace -o jsonpath='{.status.phase}')
            if ($podstatus -eq "Running") {
                # nothing to do
            }
            elseif ($podstatus -eq "Pending") {
                # Write-Information -MessageData "${pod}: $podstatus"
                $containerReady = $(kubectl get pods $pod -n $namespace -o jsonpath="{.status.containerStatuses[0].ready}")
                if ($containerReady -ne "true" ) {
                    $containerStatus = $(kubectl get pods $pod -n $namespace -o jsonpath="{.status.containerStatuses[0].state.waiting.reason}")
                    if (![string]::IsNullOrEmpty(($containerStatus))) {
                        $waitingonPod = "${waitingonPod}${pod}($containerStatus);"    
                    }
                    else {
                        $waitingonPod = "${waitingonPod}${pod}(container);"                        
                    }
                    # Write-Information -MessageData "container in $pod is not ready yet: $containerReady"
                }
            }
            else {
                $waitingonPod = "${waitingonPod}${pod}($podstatus);" 
            }
        }
            
        Write-Information -MessageData "[$counter] $waitingonPod"
    }
    while (![string]::IsNullOrEmpty($waitingonPod) -and ($counter -lt 30) )

    kubectl get pods -n $namespace -o wide

    if ($counter -gt 29) {
        Write-Information -MessageData "--- warnings in kubenetes event log ---"
        kubectl get events -n $namespace | grep "Warning" | tail    
    } 

    Write-Verbose 'WaitForPodsInNamespace: Done'
    return $Return    

}

Export-ModuleMember -Function "WaitForPodsInNamespace"