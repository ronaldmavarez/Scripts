<#
THIS SCRIPT IS TO UPDATE ALL THE WEB SITES 
AND SITE COLLECTION ON A SHAREPOINT APP.

THIS HAS BEEN TESTED ON SP2010 WITH POWERSHELL 2.0
THIS MAY WORK ON BEFORE SP VERSIONS, TO CHECK THE POWERSHELL
VERSION IN YOUR SERVER USE $host.version

Ronald Mavarez
06/13
#>

Add-PSSnapin Microsoft.SharePoint.PowerShell

[Reflection.Assembly]::LoadWithPartialName("System.Globalization") | out-null
clear-host

#THIS IS THE VARIABLE WHERE YOU SET YOUR SITE
$mysiteUrl = ""

#reset the arrays
$goodSiteURLs = @() 
$errorSiteURLs = @()
$siteURLs = @()

<#
GETTING ALL THE URLs, THIS INCLUDE SITE COLLECTION AND WEBs
#>
#The code below is the one that takes the URL of the site collections
$SiteCols = Get-SPWebApplication $mysiteURL | Get-SPSiteAdministration -Limit ALL | Select URL
foreach ($siteCol in $SiteCols){
    $currentSiteURL = $siteCol.url
    
    #just add the item if you have a URL
    if($currentSiteURL){
        $siteURLs += @($currentSiteURL)
    }#end if
}#end foreach

#The code below is the one that takes the URL of the sites
$Sites = Get-SPSite $mysiteUrl | Get-SPWeb -Limit All | Select URL
foreach ($siteCol in $Sites){
    $currentSiteURL = $siteCol.url
    
    #just add the item if you have a URL
    if($currentSiteURL){
        $siteURLs += @($currentSiteURL)
    }#end if
}#end foreach

#HERE IS WHERE THE ACTION BEGINS!
foreach ($currentSiteURL in $siteURLs){
    
    #just works if you have a URL
    if($currentSiteURL){
        #try catch inside of a foreach???
        try {
            Get-SPWeb $currentSiteURL -limit all |%{
                #Setting the values to the properties
                $_.Locale = [System.Globalization.CultureInfo]::GetCultureInfo("nb-NO") #Most used nb-NO / en-GB
                $_.RegionalSettings.WorkDayStartHour = 480 #Set hours with minutes, ex: 60 * 8 => 480
                $_.RegionalSettings.WorkDayEndHour = 960 #same as before
                $_.RegionalSettings.TimeZone.ID = 4	#4 = (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
                $_.RegionalSettings.CalendarType = 1 #Gregorian
                $_.RegionalSettings.WorkDays = 62 #0111110 Mon-Fri, this is a binary sum of 7 digits

                $_.Update()
                $goodSiteURLs += @($currentSiteURL) 
            }#end GET-SPWeb
        }catch{
          $errorSiteURLs += @($currentSiteURL)
        }#end try
    }#end if when URL
}#foreach

if ($errorSiteURLs.length -gt 0 ){
    write-host "There was a problem with the site (s) listed below, you have to fix it manually at _layouts/regionalsetng.aspx"
    write-host ""
    foreach ($site in $errorSiteURLs){
        write-host $site
    }#foreach
}#end if

write-host "The script has sucesfully update" $goodSiteURLs.length"/"$siteURLs.length "site(s) with" $errorSiteURLs.length "error (s)"