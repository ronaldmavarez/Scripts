#Created By: Ronald Mavarez
#Created date: 08.2023
#PnP Version: 2.2.0

#What: Remove from SharePoint AD groups that were removed from Azure AD
#Why: In order to keep the sites clean and avoid misunderstandings
#When: N/A
#Where: This script does not need to be saved in any specific place, it can be run from the script server

#Note: This script does not remove AD groups that are Site Collection Admins, and it does not check sub-sites

$tenantDomainUrl = "tenant.onmicrosoft.com"
$appClientID = ""
$certThumprint = ""
$siteURL = "https://tenant.sharepoint.com"
$adGroupToken = "c:0t.c|tenant|"

Connect-PnPOnline -Url $siteURL -Tenant $tenantDomainUrl -ClientId $appClientID -Thumbprint $certThumprint #works if cert is installed

$sites = @(Get-PnPTenantSite -Filter "Url -like '/sites/'").Where({ $_.Template -ne "RedirectSite#0" }) #covering rest of the sites
$siteURLs = $sites.Url

#Get all the groups from Azure AD 
$azureADGroups = Get-PnPAzureADGroup | Select-Object Id, DisplayName, MailNickname

$infos = New-Object -TypeName "System.Collections.ArrayList" #Array to collect all the info
$siteURLs.foreach({
    $percentComplete = ($siteURLs.IndexOf($_) / $siteURLs.Count) * 100
    Write-Progress -Activity "Search in Progress" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
    $siteURL = $_

    Write-Host "Processing $siteURL" -ForegroundColor Green
    Connect-PnPOnline -Url $siteURL -Tenant $tenantDomainUrl -ClientId $appClientID -Thumbprint $certThumprint #works if cert is installed

    #Collect all the groups that are assigned to the site, and get the DisplayName from AD as well. #c:0t.c is group token 
    $localADGroups = @(Get-PnPUser).Where({ $_.LoginName.StartsWith($adGroupToken) }).foreach({
        $groupSID = $_.LoginName.Replace($adGroupToken,"")
        [PSCustomObject]@{ 
            LoginName = $_.LoginName
            SID = $groupSID
            LocalName = $_.Title
            ADName = @($azureADGroups.Where({ $_.Id -eq $groupSID })).DisplayName
        }
    })

    #collect the groups that are deleted in the AD but present in SharePoint
    $deletedLocalADGroups = @($localADGroups.Where({ !$azureADGroups.ID.Contains($_.SID) }))

    if($deletedLocalADGroups.Count -gt 0){ #if groups to delete are found
        $info = "$siteURL contains $($deletedLocalADGroups.Count) adGroup(s) to delete"
        $infos.Add($info) | Out-Null #Suppressing output
        Write-Host $info -ForegroundColor Red

        $deletedLocalADGroups.foreach({
            $groupLoginName = $_.LoginName

            $ctx = Get-PnPContext 
            $ctx.Web.SiteUsers.RemoveByLoginName($groupLoginName) #remove the group from SharePoint site
            $ctx.ExecuteQuery()
        })
    }
})

#Print Out the info
$infos
