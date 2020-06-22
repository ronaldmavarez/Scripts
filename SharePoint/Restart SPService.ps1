#Tested in SharePoint 2016

Add-PSSnapin Microsoft.SharePoint.PowerShell
$serviceName = “Word Automation Services”
#$serviceName = “App Management Service”

function WaitForJobToFinish()
{ 
    $JobName = "*job-service-instance*"
    $job = Get-SPTimerJob | ?{ $_.Name -like $JobName }
    if ($job -eq $null) 
    {
        Write-Host 'Timer job not found'
    }
    else
    {
        $JobFullName = $job.Name
        Write-Host -NoNewLine "Waiting to finish job $JobFullName"
        
        while ((Get-SPTimerJob $JobFullName) -ne $null) 
        {
            Write-Host -NoNewLine .
            Start-Sleep -Seconds 2
        }
        Write-Host  "Finished waiting for job.."
    }
}

$spServers = Get-SPServer | ? { $_.ServiceInstances | ? { $_.TypeName -eq $serviceName -and $_.Status -ne "Disabled" } } | ForEach-Object {
    $serverName = $_.Name

    Write-Host -ForeGroundColor Yellow "Restarting service $serviceName on $serverName"
    
    WaitForJobToFinish

    Get-SPServiceInstance -server $serverName | where-object {$_.TypeName -eq $serviceName} | Stop-SPServiceInstance -Confirm:$false

    WaitForJobToFinish

    Get-SPServiceInstance -server $serverName | where-object {$_.TypeName -eq $serviceName} | Start-SPServiceInstance -Confirm:$false
}