#This is a script to replace the existing AD Group with a new AD Group 
#The data object is a collection of the ad group information 

$adminUserLogin = "i:0#.f|membership|papasito@tenant.onmicrosoft.com"
Connect-SPOService -Url "https://tenant-admin.sharepoint.com"
Connect-PnPOnline -Url "https://tenant-admin.sharepoint.com" -Interactive -ReturnConnection

$data = @(
    [PSCustomObject]@{ OldGroupSID = ""; OldGroupName = "Old Group Name 1"; OldADGroupMembers = @(); NewGroupSID = ""; NewGroupName = "New Group Name 1"; NewADGroupMembers = @(); MembersToBeAdded = @(); MembersToBeAddedCount = 0; MembersToBeRemoved = @(); MembersToBeRemovedCount = 0; }
    [PSCustomObject]@{ OldGroupSID = ""; OldGroupName = "Old Group Name 2"; OldADGroupMembers = @(); NewGroupSID = ""; NewGroupName = "New Group Name 2"; NewADGroupMembers = @(); MembersToBeAdded = @(); MembersToBeAddedCount = 0; MembersToBeRemoved = @(); MembersToBeRemovedCount = 0; }
    [PSCustomObject]@{ OldGroupSID = ""; OldGroupName = "Old Group Name 3"; OldADGroupMembers = @(); NewGroupSID = ""; NewGroupName = "New Group Name 3"; NewADGroupMembers = @(); MembersToBeAdded = @(); MembersToBeAddedCount = 0; MembersToBeRemoved = @(); MembersToBeRemovedCount = 0; }
)

$azureADGroups = Get-PnPAzureADGroup | Select-Object Id, DisplayName, MailNickname #Get all Azure AD groups
foreach ($row in $data) { #Foreach to fill up the data, in this code we are getting the members of old group recursively because they have nested ad groups
    $oldADGroup = $azureADGroups | Where-Object { $_.MailNickname -eq $row.OldGroupName }
    $newADGroup = $azureADGroups | Where-Object { $_.DisplayName -eq $row.NewGroupName }

    if ($oldADGroup -eq $null -or $newADGroup -eq $null){
        $wrongInfo += "$($row.OldGroupName) - $($row.NewGroupName)"
        Write-Host "Check the following old group:" $row.OldGroupName -ForegroundColor Red
        continue
    }

    # $index = 0; $groups2Check = @($oldADGroup.Id)
    # Do{ #loop to check all nested groups
    #     $groupID = $groups2Check[$index]; $index++
    #     $groups2Check += Get-PnPAzureADGroupMember -Identity $groupID | Where-Object { $_.Type -eq "Group" -and !$groups2Check.Contains($_.UserPrincipalName) } | ForEach-Object { $_.UserPrincipalName } #Get the ad groups that are not already in the list
    # }while($groups2Check.Count -ne $index)
    
    # #Members of the old ad group
    # $oldADGroupMembers = $groups2Check | Foreach-Object { (Get-PnPAzureADGroupMember -Identity $_ | Where-Object { $_.Type -eq "User" }).UserPrincipalName }
    # $oldADGroupMembers = $oldADGroupMembers | select -unique 
   
    # #Members of the new ad group
    # $newADGroupMembers = (Get-PnPAzureADGroupMember -Identity $newADGroup.Id | Where-Object { $_.Type -eq "User" }).UserPrincipalName
    # $MembersToBeAdded = $newADGroupMembers | Where-Object { $oldADGroupMembers.Count -ne 0 -and !$oldADGroupMembers.Contains($_) } #This people will get permissions 
    # $MembersToBeRemoved = $oldADGroupMembers | Where-Object { $oldADGroupMembers.Count -ne 0 -and !$newADGroupMembers.Contains($_) } #This people will lose permissions

    $row.OldGroupSID = $oldADGroup.Id
    $row.NewGroupSID = $newADGroup.Id
    # $row.OldADGroupMembers = $oldADGroupMembers -join ';'
    # $row.NewADGroupMembers = $newADGroupMembers -join ';'
    # $row.MembersToBeAdded = $MembersToBeAdded -join ';'
    # $row.MembersToBeRemoved = $MembersToBeRemoved -join ';'
    # $row.MembersToBeAddedCount = $MembersToBeAdded.Count
    # $row.MembersToBeRemovedCount = $MembersToBeRemoved.Count
}

# #Open Excel: -> Data -> From Text/CSV -> Pick the file -> Open
# $data | Export-Csv "c:\temp\ADGroupsReport.csv" -NoTypeInformation -Encoding UTF8 #Report info

$sites = Get-PnPTenantSite -Filter "Url -like '/sites/'" | Where-Object { $_.Template -ne "RedirectSite#0" } #covering rest of the sites
$siteURLs = $sites.Url

foreach ($siteURL in $siteURLs) {
    Set-SPOUser -site $siteUrl -LoginName $adminUserLogin -IsSiteCollectionAdmin $True | out-null #Set the user as site collection admin
    Write-Host "Processing $siteURL" -ForegroundColor Green
    Connect-PnPOnline -Url $siteURL -Interactive
    $adGroupToken = "c:0t.c|tenant|"

    #Fixing SharePoint Groups
    Write-Host "Processing SP Groups" -ForegroundColor Yellow
    $siteGroups = Get-PnPGroup
    foreach ($siteGroup in $siteGroups){ #$siteGroup = $siteGroups[0]
        $groupMembers = Get-PnPGroupMember -Group $siteGroup.Title
        $groupMembers2Fix = $groupMembers | Where-Object { $data.OldGroupSID.Contains($_.LoginName.Replace($adGroupToken, "")) }

        foreach ($user in $groupMembers2Fix){
            $oldADGroupID = $user.LoginName.Replace($adGroupToken, "")
            $newADGroupIDWithToken = $adGroupToken + ($data | Where-Object { $_.OldGroupSID -eq $oldADGroupID }).NewGroupSID

            Add-PnPGroupMember -LoginName $newADGroupIDWithToken -Group $siteGroup.Title
            Remove-PnPGroupMember -LoginName $user.LoginName -Group $siteGroup.Title
        }
    }

    #Web Permissions
    Write-Host "Processing web permissions" -ForegroundColor Yellow
    $web = Get-PnPWeb
    Get-PnPProperty -ClientObject $web -Property @("RoleAssignments") | Out-null
    $web.RoleAssignments | ForEach-Object { Get-PnPProperty -ClientObject $_ -Property @("RoleDefinitionBindings", "Member") | Out-null }
    $webRoleAss = $web.RoleAssignments | Where-Object { $_.RoleDefinitionBindings.Name -ne "Limited Access" -and $data.OldGroupSID.Contains($_.Member.LoginName.Replace($adGroupToken, "")) }

    foreach ($roleAss in $webRoleAss) { #$roleAss = $webRoleAss[0]
        $oldADGroupID = $roleAss.Member.LoginName.Replace($adGroupToken, "")
        $oldADGroupIDWithToken = $roleAss.Member.LoginName
        $newADGroupIDWithToken = $adGroupToken + ($data | Where-Object { $_.OldGroupSID -eq $oldADGroupID }).NewGroupSID
        
        foreach ($rolDefBinding in $roleAss.RoleDefinitionBindings | Where-Object { $_.Name -ne "Limited Access" }) { #$rolDefBinding = $roleAss.RoleDefinitionBindings[0]
            #$rolDefBinding.Name
            Set-PnPWebPermission -User $newADGroupIDWithToken -AddRole $rolDefBinding.Name
            Set-PnPWebPermission -User $newADGroupIDWithToken -RemoveRole $rolDefBinding.Name
        }
    }

    #List Permissions
    Write-Host "Processing lists with unique permissions" -ForegroundColor Yellow
    $cpLists = Get-PnPList -Includes HasUniqueRoleAssignments, RoleAssignments | Where-Object { $_.HasUniqueRoleAssignments -eq $true -and $_.Hidden -eq $false }    
    if($cpLists.Count -gt 0){
        $cpLists.RoleAssignments | ForEach-Object { Get-PnPProperty -ClientObject $_ -Property @("RoleDefinitionBindings", "Member") | Out-null }
        foreach ($list in $cpLists) { #$list = $cpLists[0]
            $listRoleAssAll = $list.RoleAssignments #| Where-Object { $_.Member.PrincipalType -eq 'SecurityGroup' }
            $listRoleAss2Check = $listRoleAssAll | Where-Object { $_.Member.PrincipalType -eq 'SecurityGroup' -and $data.OldGroupSID.Contains($_.Member.LoginName.Replace($adGroupToken, "")) -and $_.RoleDefinitionBindings.Name -ne "Limited Access" }
            
            foreach ($roleAss in $listRoleAss2Check) { #$roleAss = $listRoleAss2Check[0]
                $oldADGroupID = $roleAss.Member.LoginName.Replace($adGroupToken, "")
                $oldADGroupIDWithToken = $roleAss.Member.LoginName
                $newADGroupIDWithToken = $adGroupToken + ($data | Where-Object { $_.OldGroupSID -eq $oldADGroupID }).NewGroupSID
                
                foreach ($rolDefBinding in $roleAss.RoleDefinitionBindings | Where-Object { $_.Name -ne "Limited Access" }) { #$rolDefBinding = $roleAss.RoleDefinitionBindings[0]
                    #$rolDefBinding.Name
                    Set-PnPListPermission -Identity $list.Title -User $newADGroupIDWithToken -AddRole $rolDefBinding.Name
                    Set-PnPListPermission -Identity $list.Title -User $oldADGroupIDWithToken -RemoveRole $rolDefBinding.Name
                }
            }
        }
    }    

    #List Item Permissions
    $ctEnabledLists = Get-PnPList -Includes Fields | Where-Object { $_.ContentTypesEnabled -eq $true -and $_.Hidden -eq $false -and $_.ItemCount -ne 0 } 
    foreach ($list in $ctEnabledLists) { #$list = $ctEnabledLists[0]
        Write-Host "Processing list '$($list.Title)' with unique permissions" -ForegroundColor Yellow
        #$uniqueRoleItems = Get-PnPListItem -List $list.Title -PageSize 5000 -Query "<View><Query><Where><IsNotNull><FieldRef Name='SharedWithDetails' /></IsNotNull></Where></Query></View>" #Unique permission items
        #$uniqueRoleItems | Foreach-Object { Get-PnPProperty -ClientObject $_ -Property @("HasUniqueRoleAssignments", "RoleAssignments") } | Out-null
        $items = Get-PnPListItem -List $list.Title -Fields "Title" -PageSize 5000 
        $items | Foreach-Object { Get-PnPProperty -ClientObject $_ -Property @("HasUniqueRoleAssignments") } | Out-null

        $uniqueRoleItems = @($items | Where-Object { $_.HasUniqueRoleAssignments -eq $true })
        if($uniqueRoleItems.Count -gt 0){
            $uniqueRoleItems | Foreach-Object { Get-PnPProperty -ClientObject $_ -Property @("RoleAssignments") } | Out-null
            $uniqueRoleItems.RoleAssignments | ForEach-Object { Get-PnPProperty -ClientObject $_ -Property @("RoleDefinitionBindings", "Member") | Out-null }
            
            foreach ($spListItem in $uniqueRoleItems) { #$spListItem = $uniqueRoleItems[1]
                $listItemRoleAss2Check = $spListItem.RoleAssignments | Where-Object { $data.OldGroupSID.Contains($_.Member.LoginName.Replace($adGroupToken, "")) -and $_.RoleDefinitionBindings.Name -ne "Limited Access" -and $_.Member.PrincipalType -eq 'SecurityGroup' }
        
                foreach ($roleAss in $listItemRoleAss2Check) {
                    $oldADGroupID = $roleAss.Member.LoginName.Replace($adGroupToken, "")
                    $oldADGroupIDWithToken = $roleAss.Member.LoginName
                    $newADGroupIDWithToken = $adGroupToken + ($data | Where-Object { $_.OldGroupSID -eq $oldADGroupID }).NewGroupSID
        
                    foreach ($rolDefBinding in $roleAss.RoleDefinitionBindings | Where-Object { $_.Name -ne "Limited Access" }) { #$rolDefBinding = $listRoleAss.RoleDefinitionBindings[0]
                        #$rolDefBinding.Name
                        Set-PnPListItemPermission -List $list.Title -Identity $spListItem.Id -User $newADGroupIDWithToken -AddRole $rolDefBinding.Name
                        Set-PnPListItemPermission -List $list.Title -Identity $spListItem.Id -User $oldADGroupIDWithToken -RemoveRole $rolDefBinding.Name
                    }
                }
            }
        }#end if
    }
    Set-SPOUser -site $siteUrl -LoginName $adminUserLogin -IsSiteCollectionAdmin $False | out-null
}#end foreach URLs