#Created By: Ronald Mavarez
#Created date: 06.2023
#PnP Version: 1.12.0
#Business Contact Person: N/A

#What: Check if the amount of items of lists are ALL searchable
#Why: there are ghost items showing up from search, these items were deleted and still visible from search
#When: When you needed
#Where: Script server or locally

$tenantName = "TenantName"
$tenantDomainUrl = "$tenantName.onmicrosoft.com"
$appClientID = ""
$certThumprint = ""
$prefix = "https://$tenantName.sharepoint.com"

Connect-PnPOnline -Url $prefix -Tenant $tenantDomainUrl -ClientId $appClientID -Thumbprint $certThumprint #works if cert is installed

$siteURLs = @(Get-PnPTenantSite | Where-Object { $_.Url.Contains('/sites/') -and $_.Template -ne "RedirectSite#0" }).Url #-like '*vc-jv-*'

$brokenDocsInfo = New-Object -TypeName "System.Collections.ArrayList"
foreach($siteURL in $siteURLs){ #Foreach in all the sites
    Connect-PnPOnline -Url $siteURL -Tenant $tenantDomainUrl -ClientId $appClientID -Thumbprint $certThumprint #works if cert is installed
    Write-Host "Processing the site: $siteURL $($siteURLs.IndexOf($siteURL))/$($siteURLs.Count) " -ForegroundColor Yellow
    $lists = (Get-PnPList).Where({ ($_.BaseTemplate -eq 100 -or $_.BaseTemplate -eq 101) -and $_.Hidden -eq $false }) | select Title, BaseTemplate, DefaultViewUrl, BaseType, Hidden

    $lists.foreach({ #$list = $lists[2] #Foreach in all the list founded
        $listTitle = $_.Title
        $arrListUrl = $_.DefaultViewUrl.Split("/")
        $listURL = $arrListUrl[1] + "/" + $arrListUrl[2] + "/" + $arrListUrl[3] + "/*"
        $listQuery = 'PARENTLINKSORTABLE:"https://' + $tenantName + '.sharepoint.com/{ListURL}"'.Replace("{ListURL}", $listURL)
        
        #Collect the data from Search and List
        $searchResults = Submit-PnPSearchQuery -Query $listQuery -All
        $listItems = @(Get-PnPListItem -List $listTitle -PageSize 5000 -Fields "ID","FileRef")
    
        Write-Host "Procesing $($listTitle) with $($listItems.Count) List Item(s) and $($searchResults.RowCount) Search Item(s)" -ForegroundColor Green
        $listItemsMissingFromSearch = New-Object -TypeName "System.Collections.ArrayList"; $searchItemsMissingFromListItems = New-Object -TypeName "System.Collections.ArrayList"
        
        $searchResults.ResultRows.Path.Where({ ![string]::IsNullOrEmpty($_) }).foreach({ #Verify the search results 
            $relPath = $_.Replace($prefix, '').Replace("%2523", "#")
            $exist = @($listItems.Where({ $_.FieldValues.FileRef -eq $relPath -or $relPath.EndsWith("aspx?ID=$($_.Id)") })).Count -eq 1 
            if(!$exist){
                $searchItemsMissingFromListItems.Add($relPath) | Out-Null #Suppressing output
            }
        })
        
        $listItems.foreach({ #Verify the list items  
            $fileRef = $prefix + $_.FieldValues.FileRef.Replace("#", "%2523")
            $listItemID = $_.Id
            $exist = @($searchResults.ResultRows.Path.Where({ $_ -eq $fileRef -or $_.EndsWith("aspx?ID=$listItemID") })).Count -eq 1
            if(!$exist){
                $listItemsMissingFromSearch.Add($_.FieldValues.FileRef) | Out-Null #Suppressing output
            }
        })
        
        $info = ""
        if($listItemsMissingFromSearch.Count -gt 0){
            $info += "$($listItemsMissingFromSearch.Count) item(s) missing from search"
        }
        if($searchItemsMissingFromListItems.Count -gt 0){
            if(![string]::IsNullOrEmpty($info)){
                $info += " - "
            }

            $info += "$($searchItemsMissingFromListItems.Count) item(s) in search that doesn't exist"
        }
        if(![string]::IsNullOrEmpty($info)){ #If there's something to log
            $info = "$($siteURL): $($listTitle) has $info"
            Write-Host $info -ForegroundColor Red
            
            $listItemsMissingFromSearch.foreach({
                $FileLoc = $_

                $temp = @(
                    [PSCustomObject]@{ 
                        Status = "ListItemMissingFromSearch"
                        SiteURL = $siteURL
                        LibName = $listTitle
                        FileName = Split-Path -Leaf $FileLoc
                        FileLoc = $FileLoc
                    }
                )
                $brokenDocsInfo.Add($temp) | Out-Null #Suppressing output
            })

            $searchItemsMissingFromListItems.foreach({
                $FileLoc = $_

                $temp = @(
                    [PSCustomObject]@{ 
                        Status = "SearchItemMissingFromLib"
                        SiteURL = $siteURL
                        LibName = $listTitle
                        FileName = Split-Path -Leaf $FileLoc
                        FileLoc = $FileLoc
                    }
                )
                $brokenDocsInfo.Add($temp) | Out-Null #Suppressing output
            })
        }
    }) #End foreach list
}#end foreach siteURLs

$filePath = "C:\TEMP\BrokenDocsInfo.csv"
$brokenDocsInfoArray = @(); $brokenDocsInfoArray = $brokenDocsInfo.foreach({ $_ }) #stupid hack because System.Collections.ArrayList doesn't work when exporting CSVs 
$brokenDocsInfoArray | Export-Csv $filePath -NoTypeInformation -Encoding UTF8
