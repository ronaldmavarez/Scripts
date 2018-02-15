Add-PSSnapin Microsoft.SharePoint.PowerShell

[Reflection.Assembly]::LoadWithPartialName("System.Globalization") | out-null
clear-host

#reset the arrays
$allDocLibsURLs = @()
$goodDocLibsURLs = @() 
$errorDocLibsURLs = @()
$siteURLs = @()

<#
GETTING ALL THE URLs, THIS INCLUDE SITE COLLECTION AND WEBs
#>
#THIS IS THE VARIABLE WHERE YOU SET YOUR SITE
$currentWebAppUrl = "https://SharePointURL"
$SiteColls = Get-SPWebApplication $currentWebAppUrl | Get-SPSiteAdministration -Limit ALL | Select URL

<#
#IF JUST A SITE COLLECTION INSTEAD OF THE ALL WEBAPP
$SiteColls = New-Object System.Object
$SiteColls | Add-Member -type NoteProperty -name url -Value "https://enicom-dev.eninorge.pri/ict_im"
#>

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

#remove duplicates
$siteURLs = $siteURLs | select -uniq

#HERE IS WHERE THE ACTION BEGINS!
foreach ($currentSiteURL in $siteURLs){
    #just works if you have a URL
    if($currentSiteURL){
        try {
            Get-SPWeb $currentSiteURL -limit all | % {
                #Write-Host "Starting the list reading in: " $_.Title
                
                #DocumentLibrary = 101
                $spLists = $_.Lists | ? { $_.BaseTemplate -eq 101 }
                $libURLs = ""
                foreach($spList in $spLists){
                    try {
                        $libURLs = $spList.DefaultViewUrl
                        $allDocLibsURLs += @($libURLs)

                        ##########################
                        ##########################
                        #### LOGIC GOES HERE #####
                        ##########################
                        ##########################

                        #what doesn't goes to the catch
                        $goodDocLibsURLs += @($libURLs)
                    }catch{
                        $errorDocLibsURLs += @($libURLs)
                    }#end try catch
                }#end foreach
            }#end GET-SPWeb
        }catch{
            #Write-Host "error"
        }#end try
    }#end if when URL
}#foreach

if ($goodDocLibsURLs.length -gt 0 ){
    write-host "The folowing libraries (" $goodDocLibsURLs.length ") went OK"
    write-host ""
    
    foreach ($url in $goodDocLibsURLs){
        write-host $url
    }#foreach

    write-host "---------------------------------"
    write-host "---------------------------------"
    write-host "---------------------------------"
}#end if

if ($errorDocLibsURLs.length -gt 0 ){
    write-host "The folowing libraries (" $errorDocLibsURLs.length ") went wrong"
    write-host ""
    
    foreach ($url in $errorDocLibsURLs){
        write-host $url
    }#foreach

    write-host "---------------------------------"
    write-host "---------------------------------"
    write-host "---------------------------------"
}#end if

write-host "The script processed " $goodDocLibsURLs.length"/"$allDocLibsURLs.length "Libraries with" $errorDocLibsURLs.length "error (s)" 