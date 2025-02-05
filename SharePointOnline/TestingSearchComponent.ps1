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
foreach($siteURL in $siteURLs){ #Foreach in all the sites #$siteURL = $siteURLs[5]
    Connect-PnPOnline -Url $siteURL -Tenant $tenantDomainUrl -ClientId $appClientID -Thumbprint $certThumprint #works if cert is installed
    Write-Host "Processing the site: $siteURL $($siteURLs.IndexOf($siteURL))/$($siteURLs.Count) " -ForegroundColor Yellow
    $lists = (Get-PnPList).Where({ !$systemLibs.Contains($_.Title) -and ($_.BaseTemplate -eq 101) -and $_.Hidden -eq $false }) | select Title, BaseTemplate, DefaultViewUrl, BaseType, Hidden

    $lists.foreach({ #$list = $lists[2] #Foreach in all the list founded
        $list = $_
        $listTitle = $list.Title #$listTitle = $list.Title

        $infoProgress = "Site:$($siteURLs.IndexOf($siteURL))/$($siteURLs.Count) - List:$($lists.IndexOf($list))/$($lists.Count) ($($listTitle))"
        $percentComplete = ($lists.IndexOf($list) / $lists.Count) * 100
        Write-Progress -Activity $infoProgress -Status "$percentComplete% Complete:" -PercentComplete $percentComplete

        $arrListUrl = $list.DefaultViewUrl.Split("/") #$arrListUrl = $list.DefaultViewUrl.Split("/")
        $listURL = $arrListUrl[1] + "/" + $arrListUrl[2] + "/" + $arrListUrl[3] + "/*"
        $listQuery = 'PARENTLINKSORTABLE:"https://' + $tenantName + '.sharepoint.com/{ListURL}"'.Replace("{ListURL}", $listURL)
        
        #Collect the data from Search and List
        $retries = 0
        do {
            $searchResults = Submit-PnPSearchQuery -Query $listQuery -All
            $retries++
        } while ($searchResults.RowCount -eq 0 -and $retries -lt 5)

        $listItems = @(Get-PnPListItem -List $listTitle -PageSize 5000 -Fields "ID","FileRef")
    
        Write-Host "Procesing $($listTitle) with $($listItems.Count) List Item(s) and $($searchResults.RowCount) Search Item(s)" -ForegroundColor Green
        $listItemsMissingFromSearch = New-Object -TypeName "System.Collections.ArrayList"; $searchItemsMissingFromListItems = New-Object -TypeName "System.Collections.ArrayList"
        
        $searchItemsMissingFromListItems = $searchResults.ResultRows.Where({ ![string]::IsNullOrEmpty($_.Path) }).foreach({ #Verify the search results 
            $relPath = $_.Path.Replace($prefix, '').Replace("%23", "#")
            $exist = @($listItems.Where({ $_.FieldValues.FileRef -eq $relPath -or $relPath.EndsWith("aspx?ID=$($_.Id)") })).Count -eq 1 
            if(!$exist){
                [PSCustomObject]@{
                    RelPath = $relPath
                    CreatedTime = $_.Write
                    LastModifiedTime = $_.LastModifiedTime
                }
            }
        })#end foreach

        $listItemsMissingFromSearch = $listItems.foreach({ #Verify the list items  
            $fileRef = $prefix + $_.FieldValues.FileRef.Replace("#", "%23")
            $listItemID = $_.Id
            $exist = @($searchResults.ResultRows.Path.Where({ $_ -eq $fileRef -or $_.EndsWith("aspx?ID=$listItemID") })).Count -eq 1
            if(!$exist){
                [PSCustomObject]@{
                    RelPath = $_.FieldValues.FileRef
                    CreatedTime = if([string]::IsNullOrEmpty($_.FieldValues.Created_x0020_Date)){ $_.FieldValues.Created }else{ $_.FieldValues.Created_x0020_Date }
                    LastModifiedTime = if([string]::IsNullOrEmpty($_.FieldValues.Last_x0020_Modified)){ $_.FieldValues.Modified }else{ $_.FieldValues.Last_x0020_Modified }
                }
            }
        })#end foreach

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
            #if flag is true, it might be that there are no errors 
            $flag = $listItemsMissingFromSearch.Count -eq $searchItemsMissingFromListItems.Count
            #$status = if ($flag) { "OK?" } else { "Broken" } 
            $status = $flag ? "OK?" : "Broken"
        
            $info = "$($siteURL): $($listTitle) has $info"
            Write-Host $info -ForegroundColor Red
            
            $listItemsMissingFromSearch.foreach({
                $temp = @(
                    [PSCustomObject]@{ 
                        Flag = $status
                        Status = "ListItemMissingFromSearch"
                        SiteURL = $siteURL
                        LibName = $listTitle
                        CreatedTime = $_.CreatedTime
                        LastModifiedTime = $_.LastModifiedTime
                        FileName = Split-Path -Leaf $_.RelPath
                        FileLoc = $_.RelPath
                    }
                )
                $brokenDocsInfo.Add($temp) | Out-Null #Suppressing output
            })

            $searchItemsMissingFromListItems.foreach({
                $temp = @(
                    [PSCustomObject]@{ 
                        Flag = $status
                        Status = "SearchItemMissingFromLib"
                        SiteURL = $siteURL
                        LibName = $listTitle
                        CreatedTime = $_.CreatedTime
                        LastModifiedTime = $_.LastModifiedTime
                        FileName = Split-Path -Leaf $_.RelPath
                        FileLoc = $_.RelPath
                    }
                )
                $brokenDocsInfo.Add($temp) | Out-Null #Suppressing output
            })
        }#end if
    }) #End foreach list
}#end foreach siteURLs

$filePath = "C:\TEMP\BrokenDocsInfo.csv"
$brokenDocsInfoArray = @(); $brokenDocsInfoArray = $brokenDocsInfo.foreach({ $_ }) #stupid hack because System.Collections.ArrayList doesn't work when exporting CSVs 
$brokenDocsInfoArray | Export-Csv $filePath -NoTypeInformation -Encoding UTF8
