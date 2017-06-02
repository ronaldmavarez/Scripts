$siteURL = "siteURL"
$featureName = "featureName"

$feature = Get-SPFeature -Site $siteURL | Where {$_.Displayname -eq $featureName }

If($feature.Status -eq "Offline")
{
	Write-Output $featureName $web"not activated, activating" > C:\log\logfile.txt
	Enable-SPFeature -Identity $featureName -URL $siteURL
}else{
    Write-Output $featureName" is already activated at "$siteURL 
}
