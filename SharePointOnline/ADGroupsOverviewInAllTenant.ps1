$tenantName = "papasito"
$tenantDomainUrl = "$($tenantName).onmicrosoft.com"
$appClientID = ""
$certThumprint = ""
$siteURL = "https://$($tenantName).sharepoint.com"

Connect-PnPOnline -Url $siteURL -Tenant $tenantDomainUrl -ClientId $appClientID -Thumbprint $certThumprint #works if cert is installed

$sites = Get-PnPTenantSite -Filter "Url -like '/sites/" | Where-Object { $_.Template -ne "RedirectSite#0" } #covering rest of the sites
$siteURLs = $sites.Url

$infos = @(); $adGroupToken = "c:0t.c|tenant|"
$azureADGroups = Get-PnPAzureADGroup | Select-Object Id, DisplayName, MailNickname #Get all Azure AD groups

$infos = foreach ($siteURL in $siteURLs) {
    # Write-Host "$siteURL ($index/$($siteURLs.Length))" -ForegroundColor Yellow
    $percentComplete = ($siteURLs.IndexOf($siteURL) / $siteURLs.Count) * 100
    Write-Progress -Activity "Collecting Site data: $($_.FieldValues.FileLeafRef)" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete 

    Connect-PnPOnline -Url $siteURL -Tenant $tenantDomainUrl -ClientId $appClientID -Thumbprint $certThumprint #works if cert is installed

    $siteCollAdminsGroupIDs = @(); $spGroupIDs = @(); $webGroupIDs = @(); $listGroupIDs = @(); $allListItemsGroupIDs = @()
    $web = Get-PnPWeb -Includes RoleAssignments
    if($null -eq $web) {
        continue
    }

    #Site Collection Admins 
    $siteCollectAdmins = Get-PnPSiteCollectionAdmin
    $siteCollAdminsGroupIDs = $siteCollectAdmins.Where({ $_.LoginName.StartsWith($adGroupToken) }).LoginName.foreach({ $_.Replace($adGroupToken, "") }) 
    # $siteCollAdminsGroupIDs 

    #SPGroup members
    $spGroupIDs = @()
    $spGroupIDs = foreach ($spGroup in Get-PnPGroup) {
        $groupMembers = @(Get-PnPGroupMember -Group $spGroup.Title).Where({ $_.LoginName -like $adGroupToken+'*' })
        if($groupMembers.Count -gt 0){
            $groupMembers.LoginName.Replace($adGroupToken, "")
        }
    }
    $spGroupIDs = @($spGroupIDs | Select-Object -unique)

    #Web Permissions
    $web.RoleAssignments.foreach({ Get-PnPProperty -ClientObject $_ -Property @("RoleDefinitionBindings", "Member") | Out-null })
    $webRoleAss = $web.RoleAssignments.where({ $_.RoleDefinitionBindings.Name -ne "Limited Access" })
    $webGroupIDs = @($webRoleAss.Member.LoginName.where({ $_ -like $adGroupToken+'*' }).foreach({ $_.Replace($adGroupToken, "") }) | select -unique)

    #List Permissions
    $uniqueLists = @(Get-PnPList -Includes HasUniqueRoleAssignments, RoleAssignments).where({ $_.HasUniqueRoleAssignments -eq $true -and $_.ContentTypesEnabled -eq $true -and $_.Hidden -eq $false })
    if($null -ne $uniqueLists.RoleAssignments) { #if there are permissions on the list
        $uniqueLists.RoleAssignments.foreach({ Get-PnPProperty -ClientObject $_ -Property @("RoleDefinitionBindings", "Member") | Out-null })
        $listRoleAss = $uniqueLists.RoleAssignments.where({ $_.RoleDefinitionBindings.Name -ne "Limited Access" })
        $listGroupIDs = @($listRoleAss.Member.LoginName.where({ $_ -like $adGroupToken+'*' }).foreach({ $_.Replace($adGroupToken, "") }) | select -unique)
        # $listGroupIDs = @($listRoleAss.Member.LoginName | Where-Object { $_ -like $adGroupToken+'*' } | ForEach-Object { $_.Replace($adGroupToken, "") } | select -unique)
    }

    <#
    #List Items Permissions #THIS IS SLOW AS HELL
    $ctEnabledLists = @(Get-PnPList).Where({ $_.ContentTypesEnabled -eq $true -and $_.Hidden -eq $false })
    $allListItems = $ctEnabledLists.foreach({ Get-PnPListItem -List $_.Title -Fields ID -PageSize 5000 })
    #$uniqueRoleItems = Get-PnPListItem -List $list.Title -PageSize 5000 -Query "<View><Query><Where><IsNotNull><FieldRef Name='SharedWithDetails' /></IsNotNull></Where></Query></View>" #Unique permission items
    $allListItems.foreach({ Get-PnPProperty -ClientObject $_ -Property @("HasUniqueRoleAssignments") }) | Out-null
    $allListItems = $allListItems.Where({ $_.HasUniqueRoleAssignments -eq $true })
    $allListItems.foreach({ Get-PnPProperty -ClientObject $_ -Property @("RoleAssignments") }) | Out-null
    $allListItems.RoleAssignments.Where({ ![string]::IsNullOrEmpty($_) }).foreach({ Get-PnPProperty -ClientObject $_ -Property @("RoleDefinitionBindings", "Member") | Out-null })
    $allListItemsRoleAss = $allListItems.RoleAssignments.Where({ $_.RoleDefinitionBindings.Name -ne "Limited Access" })
    $allListItemsGroupIDs = @($allListItemsRoleAss.Member.LoginName.Where({ $_ -like $adGroupToken+'*' }).foreach({ $_.Replace($adGroupToken, "") }) | select -unique)
    #>
    #All groups id
    $allGroupIDs =  $siteCollAdminsGroupIDs + $spGroupIDs + $webGroupIDs + $listGroupIDs + $allListItemsGroupIDs
    $allGroupIDs = @($allGroupIDs | Select-Object -unique)

    $allGroupIDs.foreach({
        $adGroupID = $_
        $PermLevel = ""

        if($siteCollAdminsGroupIDs.Count -gt 0 -and $siteCollAdminsGroupIDs.Contains($adGroupID)){
            $PermLevel += "SiteCollectionAdmin "
        }
        if($spGroupIDs.Count -gt 0 -and $spGroupIDs.Contains($adGroupID)){
            $PermLevel += "SPGroup "
        }
        if($webGroupIDs.Count -gt 0 -and $webGroupIDs.Contains($adGroupID)){
            $PermLevel += "SPSite "
        }
        if($listGroupIDs.Count -gt 0 -and $listGroupIDs.Contains($adGroupID)){
            $PermLevel += "SPList "
        }
        if($allListItemsGroupIDs.Count -gt 0 -and $allListItemsGroupIDs.Contains($adGroupID)){
            $PermLevel += "SPListItem "
        }

        [PSCustomObject]@{
            SiteURL = $siteUrl
            ADGroupID = $adGroupID
            ADGroupName = ($azureADGroups.where({ $_.Id -eq $adGroupID })).DisplayName
            PermLevel = $PermLevel.Trim()
        }
    })
}#end foreach

$infos | Export-Csv -Path C:\Temp\GroupPermissions.csv -NoTypeInformation -Encoding UTF8