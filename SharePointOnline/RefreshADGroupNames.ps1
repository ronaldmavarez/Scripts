#What:Refresh the ad group names in SharePoint Online
#Reason: People change the display name of AD groups in the AAD
#Why to run this?: To avoid missunderstainds when you try to find the AD group name in SharePoint Online
#How: Iterate between sites to identify out of date AD group names

$tenantSiteUrl = "https://whatever-admin.sharepoint.com"
Connect-SPOService -Url $tenantSiteUrl 
Connect-PnPOnline -Url $tenantSiteUrl -Interactive
$adminUserLogin = "i:0#.f|membership|YourUser@whatever.onmicrosoft.com" #admin user login
$adGroupToken = "c:0t.c|tenant|"

$siteURLs = (Get-PnPTenantSite -Filter "Url -like '/sites/'" | Where-Object { $_.Template -ne "RedirectSite#0" }).Url #get all sites except redirect sites

$azureADGroups = Get-PnPAzureADGroup | Select-Object Id, DisplayName, MailNickname #Get all Azure AD groups
$infos = @() #collect all info
foreach ($siteURL in $siteURLs){ 
    Write-Host "Processing $siteURL" -ForegroundColor Green
    Set-SPOUser -site $siteUrl -LoginName $adminUserLogin -IsSiteCollectionAdmin $true | Out-Null #adds the admin role to the site
    Connect-PnPOnline -Url $siteURL -Interactive
    
    #Collect all the groups that are assigned to the site, and get the DisplayName from AD as well. #c:0t.c is group token 
    $localADs = Get-PnPUser | Where-Object { $_.LoginName.StartsWith($adGroupToken) } | ForEach-Object { 
        $groupSID = $_.LoginName.Replace($adGroupToken,"")
        [PSCustomObject]@{ 
            LoginName = $_.LoginName
            SID = $groupSID
            LocalName = $_.Title
            ADName = ($azureADGroups | Where-Object { $_.Id -eq $groupSID }).DisplayName
        }
    }

    #Foreach with all the groups that needs an update
    $localADs | Where-Object { $_.LocalName -ne $_.ADName -and $null -ne $_.ADName } | ForEach-Object {
        $info = "Updating from '$($_.LocalName)' to '$($_.ADName)' - $($_.SID) - $siteURL"
        $infos += $info
        Write-Host $info -ForegroundColor Yellow

        $ctx = Get-PnPContext
        $web = $ctx.Web
        #Resolve the AD Security Group
        $ADGroup = $web.EnsureUser($_.LoginName)
        $ADGroup.Title = $_.ADName
        $ADGroup.Update()
        $ctx.ExecuteQuery()
    }

    Set-SPOUser -site $siteUrl -LoginName $adminUserLogin -IsSiteCollectionAdmin $false | Out-Null #removes the admin role from the site
}