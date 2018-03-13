Add-PSSnapin *sharepoint*

<#
GETTING ALL THE URLs, THIS INCLUDE SITE COLLECTION AND WEBs
#>
#THIS IS THE VARIABLE WHERE YOU SET YOUR SITE
$siteURLs = @()
$adGroups = @()
$adUsers = @()

$currentWebAppUrl = "https://SharePointURL"
$SiteColls = Get-SPWebApplication $currentWebAppUrl | Get-SPSiteAdministration -Limit ALL | Select URL

foreach ($SiteColl in $SiteColls){
    $currentSiteURL = $SiteColl.url
    
    #just add the item if you have a URL
    if($currentSiteURL){
        
        $site = Get-SPSite $currentSiteURL

        foreach ($subSite in $site.AllWebs){
            $siteURLs += @($subSite.url)
        }#end foreach 
    }#end if
}#end foreach

$siteURLs = $siteURLs | select -uniq

foreach ($url in $siteURLs){
    #write-host $url

    $site = new-object Microsoft.SharePoint.SPSite($url) 
    $web = $site.openweb() 
    $siteUsers = $web.SiteUsers 

    foreach($user in $siteUsers) 
    {
        if ($user.IsDomainGroup){
            $adGroups += $user.Name + " (" + $user.UserLogin + ")"
        }else{
            $adUsers += $user.LoginName + " (" + $user.Name + ")"
        }
            
        #Write-Host $user.LoginName / $user.Name / 
        
    }        

    $web.Dispose() 
    $site.Dispose() 
}#foreach

$adGroups = $adGroups | select -uniq
$adUsers = $adUsers | select -uniq

Write-Host ""
Write-Host ""
write-host "---------------------------------"
write-host "---------------------------------"
Write-Host "The Users are: "
write-host "---------------------------------"
write-host "---------------------------------"
write-host "---------------------------------"

foreach($adUser in $adUsers) 
{
    Write-Host $adUser
}

Write-Host ""
Write-Host ""
write-host "---------------------------------"
write-host "---------------------------------"
Write-Host "The Groups are: "
write-host "---------------------------------"
write-host "---------------------------------"

foreach($adGroup in $adGroups) 
{
    Write-Host $adGroup
}