#This is a script to get all the Term Set that are being used in the site
#This version of the script checks if any document or list item uses the term set, however, we need to check if the term set is being used in list columns

$siteURLs = @( 
    "https://tenant.sharepoint.com/sites/site1"
); 

Set-Location -Path "C:\GitHub\Repo\" 
. .\Lib\Functions.ps1 

$report1 = @() 
$globalDocTypes = @() 
foreach ($siteURL in $siteURLs) { #$siteURL = $siteURLs[0] 
    Write-Host "Processing site: $siteURL" -ForegroundColor Green 
    Connect-PnPOnline -Url $siteURL -Interactive 
    $ctEnabledLists = Get-PnPList | Where-Object { $_.ContentTypesEnabled -eq $true -and $_.Hidden -eq $false -and $_.ItemCount -ne 0 } 

    foreach ($ctEnabledList in $ctEnabledLists) { #$ctEnabledList = $ctEnabledLists[0] 
        $localDocTypes = @() 
        $listItemsAll = @(Get-PnPListItem -List $ctEnabledList.Title -Connection $pnpConnect -PageSize 5000) 
         
        $localDocTypes += $listItemsAll | ForEach-Object { GetDocType $_ } 
        $localDocTypes = @($localDocTypes | Where-Object { ![string]::IsNullOrEmpty($_) }) #remove empty values 
        $globalDocTypes += $localDocTypes 

        $cleanDocTypes = @($localDocTypes | select -Unique) 
        $cleanDocTypes = @($cleanDocTypes | Foreach-Object {  
            $cleanDocType = $_ 
            $_ + ' ('+ ($localDocTypes | Where-Object { $_ -eq $cleanDocType }).Count +')'  
        }) 

        $row = @( 
        [PSCustomObject]@{  
            SiteUrl = $siteURL 
            ListName = $ctEnabledList.Title 
            DocTypesInUsed = $cleanDocTypes -join ';' 
        }) 
         
        $report1 += $row 
    } 
} 

$report2 = @() 
$cleanGlobalDocTypes = @($globalDocTypes | select -Unique) 
foreach ($cleanGlobalDocType in $cleanGlobalDocTypes) { 
    $row = @( 
        [PSCustomObject]@{  
            DocType = $cleanGlobalDocType 
            Counter = @($globalDocTypes | Where-Object { $_ -eq $cleanGlobalDocType }).Count 
        }) 

    $report2 += $row 
} 

$report1 | Export-Csv "c:\temp\Info-SiteURL-ListName-Counter.csv" -NoTypeInformation 
$report2 | Export-Csv "c:\temp\Info-DocType-Counter.csv" -NoTypeInformation 