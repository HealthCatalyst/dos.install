<#
  .SYNOPSIS
  LaunchKubernetesDashboard
  
  .DESCRIPTION
  LaunchKubernetesDashboard
  
  .INPUTS
  LaunchKubernetesDashboard - The name of LaunchKubernetesDashboard

  .OUTPUTS
  None
  
  .EXAMPLE
  LaunchKubernetesDashboard

  .EXAMPLE
  LaunchKubernetesDashboard


#>
function LaunchKubernetesDashboard()
{
  [CmdletBinding()]
  param
  (
  )

  Write-Verbose 'LaunchKubernetesDashboard: Starting'

    # launch Kubernetes dashboard
    $launchJob = $true
    $myPortArray = 8001, 8002, 8003, 8004, 8005, 8006, 8007, 8008, 8009, 8010, 8011, 8012, 8013, 8014, 8015, 8016, 8017, 8018, 8019, 8020, 8021, 8022, 8023, 8024, 8025, 8026, 8027, 8028, 8029, 8030, 8031, 8032, 8033, 8034, 8035, 8036, 8037, 8038, 8039
    $port = $(FindOpenPort -portArray $myPortArray).Port
    Write-Host "Starting Kub Dashboard on port $port"
    # $existingProcess = Get-ProcessByPort 8001
    # if (!([string]::IsNullOrWhiteSpace($existingProcess))) {
    #     Do { $confirmation = Read-Host "Another process is listening on 8001.  Do you want to kill that process? (y/n)"}
    #     while ([string]::IsNullOrWhiteSpace($confirmation))
                
    #     if ($confirmation -eq "y") {
    #         Stop-ProcessByPort 8001
    #     }
    #     else {
    #         $launchJob = $false
    #     }
    # }
    
    if ($launchJob) {
        # https://stackoverflow.com/questions/19834643/powershell-how-to-pre-evaluate-variables-in-a-scriptblock-for-start-job
        $sb = [scriptblock]::Create("kubectl proxy -p $port")
        $job = Start-Job -Name "KubDashboard" -ScriptBlock $sb -ErrorAction Stop
        Wait-Job $job -Timeout 5;
        Write-Host "job state: $($job.state)"  
        Receive-Job -Job $job 6>&1  
    }
    
    # if ($job.state -eq 'Failed') {
    #     Receive-Job -Job $job
    #     Stop-ProcessByPort 8001
    # }
                
    # Write-Host "Your kubeconfig file is here: $env:KUBECONFIG"
    $kubectlversion = $(kubectl version --short=true)[1]
    if ($kubectlversion -match "v1.8") {
        Write-Host "Launching http://localhost:$port/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy in the web browser"
        Start-Process -FilePath "http://localhost:$port/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy";
    }
    else {
        $url = "http://localhost:$port/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/"
        Write-Host "Launching $url in the web browser"
        Write-Host "Click Skip on login screen";
        Start-Process -FilePath "$url";
    }            

  Write-Verbose 'LaunchKubernetesDashboard: Done'

}

function FindOpenPort($portArray) {
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

function global:Get-ProcessByPort( [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()] [int] $Port ) {    
    $netstat = netstat.exe -ano | Select-Object -Skip 4
    $p_line = $netstat | Where-Object { $p = ( -split $_ | Select-Object -Index 1) -split ':' | Select-Object -Last 1; $p -eq $Port } | Select-Object -First 1
    if (!$p_line) { return; } 
    $p_id = $p_line -split '\s+' | Select-Object -Last 1
    return $p_id;
}

Export-ModuleMember -Function "LaunchKubernetesDashboard"