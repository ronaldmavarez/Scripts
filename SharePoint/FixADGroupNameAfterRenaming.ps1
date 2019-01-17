#This Script will update the name of the Active Directory Groups that were renamed in the AD, SharePoint do not update the names automatically
#However, the People Picker will still show the old name of the group, this script is not fixing people at all

Add-PSSnapin *sharepoint*

function GetDomainID($domainInfo){
    $domainIDLength = $domainInfo.Length - ($domainInfo.LastIndexOf('|') + 1)
    $domainID = $domainInfo.Substring($domainInfo.LastIndexOf('|') +1 ,$domainIDLength)
    return $domainID
}

$spADGroups = @()
Get-SPSite -Limit all | % {
    $spDomainGroups = $_.OpenWeb().SiteUsers;
    $siteURL = $_.URL
    if ($spDomainGroups -ne $null) {
        foreach ($spDomainGroup in $spDomainGroups) {
            if ($spDomainGroup.UserLogin.ToString().Contains("c:0+.w|")){
                $spDomainGroupID = GetDomainID($spDomainGroup.UserLogin)
                try {
                    $adGroup = Get-ADGroup -Identity $spDomainGroupID
                    if($adGroup){
                        $adGroupName = $adGroup.Name
                        #Write-Host $spDomainGroup.DisplayName " - "  $adGroupName
                        if ($spDomainGroup.DisplayName -ne $adGroupName){
                            $user = get-spuser -identity $spDomainGroup.UserLogin -web $siteURL 

                            If($user){
                                $info = $spDomainGroup.DisplayName + " => " + $adGroupName + " (" + $spDomainGroupID + ")"
                                $spADGroups += $info

                                set-spuser -identity $user -displayname $adGroupName
                                #write-host $siteURL " - " $info
                            }
                        }
                    }
                }catch{}
            }
        }
    }
}
$spADGroups = $spADGroups | select -uniq
$spADGroups

exit #just for the Windows Task