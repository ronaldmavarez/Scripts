$tenantUrl = "https://tenant.sharepoint.com"
$systemLibs = @("Form Templates", "Master Page Gallery", "Site Assets", "Style Library", "_catalogs/hubsite", "Theme Gallery")
$ctxRequestsLimit = 25

Function GetLibToProcess {
    Param ($whiteListNames, $blackListNames)
    <#
    $whiteListNames = $objMain.WhiteListLibNames
    $blackListNames = $objMain.BlackListLibNames
    #>

    $whiteListNames = $whiteListNames.Split(";") | Where-Object { $_.Length -gt 0 }
    $blackListNames = $blackListNames.Split(";") | Where-Object { $_.Length -gt 0 }

    $libsToProcess = Get-PnPList | Select-Object Title | ForEach-Object { $_.Title }

    if($whiteListNames.Length){ #Take only the lists you would like to process
        $libsToProcess =  @($libsToProcess | Where-Object {
            $_parent = $_
            ($whiteListNames | Where-Object { $_ -eq $_parent }).Count
        })    
    }
    
    if ($blackListNames.Length){ #Exclude the lists you don't want to process
        $libsToProcess =  @($libsToProcess | Where-Object {
            $_parent = $_
            ($blackListNames | Where-Object { $_ -eq $_parent }).Count
        })    
    }

    return $libsToProcess
}

Function DeleteEmptyFolders {
    Param ($pnpConnect, $libNamesToProcess)
    #$pnpConnect = $srcConnect
    ForEach($libName in $libNamesToProcess){
        #Get all the folders in use
        $inUseFolders = (Get-PnPListItem -Connection $pnpConnect -List $libName -PageSize 5000 | Where-Object { $_.FileSystemObjectType -eq "File" } | Select-Object FieldValues | Foreach-Object { $_.FieldValues.FileDirRef })
        
        #Get all the existing folders
        $folders = (Get-PnPListItem -Connection $pnpConnect -List $libName -PageSize 5000 | Where-Object { $_.FileSystemObjectType -eq "Folder" })

        foreach ($folder in $folders) {
            if(($inUseFolders | Where-Object { $_.StartsWith($folder.FieldValues.FileRef) }).Count -eq 0){
                Write-Host "Deleting the folder:"  $folder.FieldValues.FileRef
                Remove-PnPFile -Connection $pnpConnect -ServerRelativeUrl $folder.FieldValues.FileRef -Force -Recycle
            }
        }
    }
}

Function CreateDestinationFolders{
    Param ($pnpConnect, $libNamesToProcess, $mappingTable)
    <#
    $mappingTable   = $objMain.MappingTable
    #>

    #Process all the items in $libNamesToProcess
    ForEach($libName in $libNamesToProcess){
        #$libName = $libNamesToProcess[0]
        Write-Host "Creating folders in list: $libName" -ForegroundColor Yellow

        $spList = Get-PnPList -Connection $pnpConnect | Where-Object { $_.Title -eq $libName }
        $prefixFolderUrl = $spList.RootFolder.ServerRelativeUrl + "/"

        $folders = (Get-PnPListItem -Connection $pnpConnect -List $libName -PageSize 5000 | Where-Object { $_.FileSystemObjectType -eq "Folder" })

        foreach ($item in $mappingTable) {
            #$item = $mappingTable[0]
            $fullFolderPath = $item.DestFolder
            if($fullFolderPath -ne ""){
                #Check if full path of the the folder exists
                if(($folders | Where-Object { $_.FieldValues.FileRef -eq $fullFolderPath }).Count -eq 0){
                    $folderNames = $fullFolderPath.Replace($prefixFolderUrl, "").Split("/")
        
                    $folderContainter = $prefixFolderUrl
                    foreach($folderName in $folderNames){ #Check all the folders 
                        $folderNameFullPath = $folderContainter + $folderName
        
                        if(($folders | Where-Object { $_.FieldValues.FileRef -eq $folderNameFullPath }).Count -eq 0){ #Add folders if they are not part of the $folders array
                            #Write-Host "Creating folder: $folderNameFullPath"
                            Add-PnPFolder -Connection $pnpConnect -Name $folderName -Folder $folderContainter.Substring(0,$folderContainter.Length-1) | Out-Null
                            $folders = (Get-PnPListItem -Connection $pnpConnect -List $libName -PageSize 5000 | Where-Object { $_.FileSystemObjectType -eq "Folder" }) #refresh the folder array
                        }
                        $folderContainter += "$folderName/" #Will setup the next round
                    }
                }
            }
        }
    }#End foreach

    #SetSystemAccountToAllFolders $pnpConnect #Running from another function because this code is very slow
}

Function GetDocType{
    Param ($item)
    #$item = $listItems[0]

    $docTypeValue = ""
    $docTypeFieldNames = @("DocumentType", "EniDocumentType", "DocType")
    
    if(![string]::IsNullOrEmpty($item)){
        foreach ($docTypeFieldName in $docTypeFieldNames) { #$docTypeFieldName = $docTypeFieldNames[0]
            if($item.FieldValues.ContainsKey($docTypeFieldName) -and ![string]::IsNullOrEmpty($item.FieldValues[$docTypeFieldName])){
                if ($item.FieldValues[$docTypeFieldName].GetType().Name -eq "TaxonomyFieldValue"){
                    $docTypeValue = $item.FieldValues[$docTypeFieldName].Label
                }else{
                    $docTypeValue = $item.FieldValues[$docTypeFieldName]
                }
                break
            }
        }
    }
    
    if([string]::IsNullOrEmpty($docTypeValue)){
        $docTypeValue = ''
    }
    
    return $docTypeValue
}

Function MoveFilesWithinLibrary{
    Param ($pnpConnect, $libNamesToProcess, $mappingTable, $overrideFile = $false)
    $ignoredReport = @()
    <#
    $pnpConnect = $srcConnect
    $mappingTable = $objMain.MappingTable
    $overrideFile = $true
    #>

    #Process all the items in $libNamesToProcess
    ForEach($libName in $libNamesToProcess){
        #$libName = $libNamesToProcess[0]
        $listItemsAll = @(GetSourceItemsAll $pnpConnect $libName)
        $listItems = @(GetSourceDocuments $listItemsAll)

        $srcListUrl = (Get-PnPList -Connection $pnpConnect | Where-Object { $_.Title -eq $libName }).RootFolder.ServerRelativeUrl

        Write-Host "Processing the list: $libName with: $($listItems.Count) item(s)" -ForegroundColor Yellow
        ForEach ($item in $mappingTable) { #Foreach item of your mappingTable 
            #$item = $mappingTable[4]
            $docsToMove = GetDocumentsToMove $item $srcListUrl $listItems $listItemsAll $mappingTable
            $ignoredReport += MoveDocuments $pnpConnect $libName $libName $srcListUrl $item.DestFolder $docsToMove $overrideFile
        }
    }
    return $ignoredReport
} #End function

Function MoveFilesFromAToB{
    Param ($srcConnect, $dstConnect, $srcListTitle, $dstListTitle, $mappingTable, $overrideFile = $false)
    $docsToMove = @()
    $ignoredReport = @()
    <#
    $srcListTitle = $objMain.SourceLibName
    $dstListTitle = $objMain.DestinationLibName
    $mappingTable = $objMain.MappingTable
    #>
    $srcListUrl = (Get-PnPList -Connection $srcConnect | Where-Object { $_.Title -eq $srcListTitle }).RootFolder.ServerRelativeUrl
    $dstListUrl = (Get-PnPList -Connection $dstConnect | Where-Object { $_.Title -eq $dstListTitle }).RootFolder.ServerRelativeUrl
    
    $listItemsAll = GetSourceItemsAll $srcConnect $srcListTitle
    $listItems = @(GetSourceDocuments $listItemsAll)

    Write-Host "Processing the list: $srcListTitle with: $($listItems.Count) item(s) and $($listItemsAll.Count) folder(s)" -ForegroundColor Yellow
    foreach ($item in $mappingTable) {
        #$item = $mappingTable[4]
        $docsToMove = GetDocumentsToMove $item $srcListUrl $listItems $listItemsAll $mappingTable
        $ignoredReport += MoveDocuments $dstConnect $srcListTitle $dstListTitle $dstListUrl $item.DestFolder $docsToMove $overrideFile
    }
    return $ignoredReport
}
### Exclude files within a DocSets
Function GetSourceDocuments {
    param ($listItemsAll)

    $docSets = @($listItemsAll | Where-Object { $_.FileSystemObjectType -eq "Folder" -and (![string]::IsNullOrEmpty($_.FieldValues._dlc_DocIdUrl) -or $_.FieldValues.MetaInfo.Contains("DocumentStatus:SW|Final"))})
    $docSetIDs = @($docSets | Foreach-Object { $_.ID })
    $docSetPaths = @($docSets | Foreach-Object { $_.FieldValues.FileRef })

    $listItems = @($listItemsAll | Where-Object { ($_.FileSystemObjectType -eq "File" -or $docSetIDs.Contains($_.ID)) -and !$docSetPaths.Contains($_.FieldValues.FileDirRef) })
    return $listItems
}

Function GetSourceItemsAll {
    param ($pnpConnect, $libName)
    <#
    $pnpConnect = $srcConnect
    $libName = $srcListTitle
    #>

    #$listItemsAll = @(Get-PnPListItem -List $libName -Fields "EniDocumentType", "DocumentType", "DocType", "_dlc_DocIdUrl", "FileDirRef", "FileRef", "Title", "GUID" -Connection $pnpConnect)
    #$listItemsAll = @(Get-PnPListItem -List $libName -Connection $pnpConnect)
    $listItemsAll = @(Get-PnPListItem -List $libName -Fields "EniDocumentType", "DocumentType", "DocType", "_dlc_DocIdUrl", "FileDirRef", "FileRef", "Title", "GUID" -Connection $pnpConnect -PageSize 5000)
    return $listItemsAll
}

Function MoveDocuments {
    Param ($pnpConnect, $srcListTitle, $dstListTitle, $dstListUrl, $dstListFolder, $docsToMove, $overrideFile = $false)
    $moveDocReport = @()
    <#
    $pnpConnect = $dstConnect
    $srcListTitle = $libName
    $dstListTitle = $libName
    $dstListUrl = $srcListUrl
    $dstListUrl = "/sites/test-pl716/Shared Documents"
    $dstListFolder = $item.DestFolder
    $dstListFolder = 'Temp'
    #>

    if([string]::IsNullOrEmpty($docsToMove)){
        return $moveDocReport
    }

    $destFolderPath = @{$true=$dstListUrl + "/" + $dstListFolder;$false=$dstListUrl}[($dstListFolder -ne '')]
    
    $docsToMove = @($docsToMove | Where-Object { $_.FieldValues.FileDirRef -ne $destFolderPath }) #Excluding the documents already located at the destFolderPath
    foreach($doc in $docsToMove){
        #$doc = $docsToMove[0].FieldValues
        #$item = $doc
        $docType = GetDocType $doc

        #if doc is already there, jump to the next one
        #if ($destFolderPath -eq $doc.FieldValues.FileDirRef){ continue; } #TODO: Filter to exclude docs before the foreach
        $newFileLoc = $doc.FieldValues.FileRef -Replace $doc.FieldValues.FileDirRef, $destFolderPath
        if($overrideFile -eq $false){
            $itemExistFlag = (Get-PnPListItem -Connection $pnpConnect -List $dstListTitle -PageSize 5000 | Where-Object { $_.FieldValues.FileRef -eq $newFileLoc }).Length

            if($itemExistFlag -gt 0){
                $info = "FROM:" + $doc.FieldValues.FileRef + " ($docType) TO:" + $newFileLoc
                $moveDocReport +=  $info
                Write-Host "Item already exist" $info -ForegroundColor Red
                continue;
            }
        }
        
        Write-Host "Moving:" $doc.FieldValues.FileRef "($($docType)) to: $destFolderPath" -ForegroundColor Yellow

        if($doc.FileSystemObjectType -eq "Folder" -and [string]::IsNullOrEmpty($doc.FieldValues._dlc_DocIdUrl)){ #Folder
            $siteURL = $pnpConnect.Url.Replace($tenantUrl, "") + "/"
            Move-PnPFolder -Folder $doc.FieldValues.FileRef.ToLower().Replace($siteURL.ToLower(), "") -TargetFolder $destFolderPath.ToLower().Replace($siteURL.ToLower(), "") -Connection $pnpConnect | Out-Null
            
            # $folderSourceURL = $tenantUrl + $doc.FieldValues.FileRef
            # $folderTargetURL = $tenantUrl + ($destFolderPath + '/' + $doc.FieldValues.FileLeafRef)
            # Move-SPOFolder $folderSourceURL $folderTargetURL
        }elseif ($doc.FileSystemObjectType -eq "Folder" -and ![string]::IsNullOrEmpty($doc.FieldValues._dlc_DocIdUrl)){ #DocumentSets
            Move-PnPFile -SourceUrl $doc.FieldValues.FileRef -TargetUrl $destFolderPath -Connection $pnpConnect -Overwrite -Force -AllowSchemaMismatch 
        }elseif ($doc.FileSystemObjectType -eq "File"){ #Normal Doc
            # $fileID = $doc.Id
            # $ctx = Get-PnPContext
            # $list = $ctx.web.Lists.GetByTitle($srcListTitle)
            # $listItem = $list.GetItemById($fileID)
            # $ctx.Load($listItem)
            # $ctx.ExecuteQuery()

            # $listItem.File.MoveTo($newFileLoc,1)
            # $ctx.ExecuteQuery()

            Move-PnPFile -SourceUrl $doc.FieldValues.FileRef -TargetUrl $destFolderPath -Connection $pnpConnect -Overwrite -Force -AllowSmallerVersionLimitOnDestination -AllowSchemaMismatch #AllowMissmatch because of DocPoint files
        }
    }
    return $moveDocReport
} 

#Function to Move a Folder
Function Move-SPOFolder{
    Param ($folderSourceURL, $folderTargetURL)
    Try{
        $ctx = Get-PnPContext
     
        #Move the Folder
        $moveCopyOpt = New-Object Microsoft.SharePoint.Client.MoveCopyOptions
        #$MoveCopyOpt.KeepBoth = $True
        [Microsoft.SharePoint.Client.MoveCopyUtil]::MoveFolder($ctx, $folderSourceURL, $folderTargetURL, $moveCopyOpt)
        $ctx.ExecuteQuery()
    }
    Catch {
        write-host -f Red "Error Moving the Folder!" $_.Exception.Message
    }
}

Function GetDocumentsToMove {
    Param ($item, $srcListUrl, $listItems, $listItemsAll, $mappingTable)
    $docsToMove = @()

    $srcFolderUrl = $srcListUrl
    if($item.SrcFolder -ne ""){
        $srcFolderUrl += "/" + $item.SrcFolder
    }

    if ($item.PSObject.Properties.Name.Contains("SrcFolder")){ #If Script uses SrcFolder
        if ($item.SrcFolder -eq '*'){ #Logic to move all the SrcFolder not in the list
            #* is not sopported for now
            # $srcFolders = @($mappingTable | Where-Object { $_.SrcFolder -ne '*' } | Foreach-Object { $srcListUrl + "/" + $_.SrcFolder }) #<------- CHECK THIS LOGIC
            
            # $docsToMove = $listItemsAll | Where-Object { 
            #     $temp_ = $_
            #     !@($srcFolders | Where-Object { $temp_.FieldValues.FileRef.StartsWith($_) }).Count
            # }# | ForEach-Object { $_.FieldValues.FileRef } #Works to exclude all the folders from the mapping
            
            # $docsToMove.Count #131 original
        } else {
            #$docsToMove = @($listItemsAll | Where-Object { $_.FieldValues.FileRef -eq $srcFolderUrl }) #Get the folders to move 
            $docsToMove = @($listItemsAll | Where-Object { $_.FieldValues.FileDirRef -eq $srcFolderUrl }) #Get the item(s) in folders to move 
            
            #$srcFolderUrl + "/" + $item.SrcFolder
            #$listItemsAll | ForEach-Object { $_.FieldValues.FileRef }
            #$docsToMove[0].FieldValues.FileRef
        }
    }elseif ($item.PSObject.Properties.Name.Contains("DocType")){
        if ($item.DocType -eq '*'){ #Logic to move all the DocTypes not in the list
            $docTypes = @($mappingTable | Where-Object { $_.DocType -ne '*' } | Foreach-Object { $_.DocType }) 
            $docsToMove = @($listItems | Where-Object { 
                $itemDocType = GetDocType $_
                !$docTypes.Contains($itemDocType)
            }) #Get the items to move
        } else {
            $docsToMove = @($listItems | Where-Object { (GetDocType $_) -eq $item.DocType }) #Get the items to move
        }
    }
    
    return $docsToMove
}

Function DocumentIDFixer {
    Param ($pnpConnect)
    #$pnpConnect = $srcConnect
    Write-Host "Fixing the Document IDs in ($($pnpConnect.Url))" -ForegroundColor Yellow

    #Get the lists with items and with the DocID field present, #excluding SystemLibs
    $libNamesToProcess = Get-PnPList -Includes Fields | Where-Object { $_.ItemCount -gt 0 -and !$systemLibs.Contains($_.Title) -and $_.Title -ne "Docpoint" -and $_.Title -ne "Docpoint2" } | Foreach-Object { 
        $fields = @($_.Fields | Foreach-Object { $_.InternalName })
        if($fields.Contains("_dlc_DocIdUrl")){
            $_.Title
        }
    }

    ForEach($libName in $libNamesToProcess){ #$libName = $libNamesToProcess[0]
        $items = @(Get-PnPListItem -List $libName -Connection $pnpConnect -PageSize 5000 | Where-Object { ![string]::IsNullOrEmpty($_.FieldValues._dlc_DocIdUrl) })
        #$items = @(Get-PnPListItem -List $libName -Connection $pnpConnect | Where-Object { ![string]::IsNullOrEmpty($_.FieldValues._dlc_DocIdUrl) -and !$_.FieldValues.MetaInfo.Contains("_dlc_DocIdItemGuid:SW|")}) #just item with DocID, will exclude folders
        #$items = @(Get-PnPListItem -List $libName -Connection $pnpConnect | Where-Object { !$_.FieldValues.MetaInfo.Contains("_dlc_DocIdItemGuid:SW|")})

        # $items = @(Get-PnPListItem -List $libName -Connection $pnpConnect | Where-Object { 
        #     !$_.FieldValues.MetaInfo.Contains("_dlc_DocIdItemGuid:SW|"+$_.FieldValues._dlc_DocId) -or !$_.FieldValues.MetaInfo.Contains("_dlc_DocId:SW|"+$_.FieldValues._dlc_DocId) #Doesn't really work
        # })

        $ctx = Get-PnPContext
        $list = $ctx.web.Lists.GetByTitle($libName)

        $ctxRequestsCount = 0
        foreach($item in $items){
            $ctxRequestsCount++
            $docID = $item.FieldValues._dlc_DocIdUrl.Description

            $listItem = $list.GetItemById($item.Id) 
            $listItem["_dlc_DocId"] = "123"
            $listItem.SystemUpdate()
        
            $listItem = $list.GetItemById($item.Id) 
            $listItem["_dlc_DocId"] = $docID 
            $listItem.SystemUpdate()

            if($ctxRequestsCount % $ctxRequestsLimit -eq 0){ #if reach the limit
                $ctx.ExecuteQuery()
            }
        }

        $ctx.ExecuteQuery()
        Write-Host "$($items.Length) DocID(s) in $libName fixed" -ForegroundColor Green
    }

    Write-Host "Document IDs in ($($pnpConnect.Url)) completed" -ForegroundColor Yellow
}

Function ClearRecycleBin {
    Param ($pnpConnect)
    #$libsToClear = ("Common Activities","Common Activities Restricted", "Production License Agreements", "Upstream COM Negotiations", "Upstream COM Agreements")
    #$libsToClear = @(Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and $_.ContentTypesEnabled -eq $true } | Foreach-Object { $_.Title })
    $libsToClear = ("Common Activities","Common Activities Restricted","Production License Agreements","Upstream COM Negotiations","Upstream COM Agreements", "DocPoint")

    foreach ($libName in $libsToClear) { #$libName = $libsToClear[0]
        $listURL = (Get-PnPList -Identity $libName -Connection $pnpConnect).RootFolder.ServerRelativeUrl
        $listURL = $listURL.Substring(1, $listURL.Length - 1)
        Write-Host "Item(s) and Document set(s) deleted from RecycleBin of:" $listURL -ForegroundColor Yellow
        Get-PnPRecycleBinItem -Connection $pnpConnect | Where-Object { $_.DirName.StartsWith($listURL) } | ForEach-Object {
            Clear-PnpRecycleBinItem -Identity $_.Id.Guid -Force
        }
    }
}

Function SetSystemAccountToAllFolders {
    Param ($pnpConnect)

    $systemAccountName = "Tenant O365 Admin"
    $systemAccountMail = "msO365admin@tenant.onmicrosoft.com" #papasito@tenant.onmicrosoft.com
    $modifiedDate = "2021-06-01 12:00:00 AM"
    
    $libNamesToProcess = Get-PnPList -Connection $pnpConnect | Where-Object { $_.ItemCount -gt 0 -and !$systemLibs.Contains($_.Title) -and $_.Title -ne "Docpoint" -and $_.Title -ne "Docpoint2" } | Foreach-Object { $_.Title }
    foreach ($libName in $libNamesToProcess) { #$libName = $libNamesToProcess[0]
        #$folders = @(Get-PnPListItem -Connection $pnpConnect -List $libName | Where-Object { $_.FileSystemObjectType -eq "Folder" -and [string]::IsNullOrEmpty($_.FieldValues._dlc_DocIdUrl) -and ($_.FieldValues.Author.LookupValue -ne $systemAccountName -or $_.FieldValues.Editor.LookupValue -ne $systemAccountName)}) #For some reason this doesn't work inside a function file, it works out in other context
        $folders = @(Get-PnPListItem -Connection $pnpConnect -List $libName -PageSize 5000 | Where-Object { $_.FileSystemObjectType -eq "Folder" -and [string]::IsNullOrEmpty($_.FieldValues._dlc_DocIdUrl) -and $_.FieldValues.Modified -ne $modifiedDate})

        if($folders.Length -gt 0){            
            Write-Host "Setting user account to $($folders.Length) folder(s) in:" $libName
            #$batch = New-PnPBatch
            $folders | Foreach-Object { 
                Set-PnPListItem -List $libName -Identity $_.Id -Connection $pnpConnect -Values @{"Editor"=$systemAccountMail;"Author"=$systemAccountMail;"Modified"=$modifiedDate} -UpdateType UpdateOverwriteVersion | Out-Null #SystemUpdate doesn't update ModifiedBy
                #Set-PnPListItem -List $libName -Identity $_.Id -Connection $pnpConnect -Values @{"Editor"=$systemAccountMail;"Author"=$systemAccountMail;"Modified"=$modifiedDate} -UpdateType UpdateOverwriteVersion -Batch $batch #SystemUpdate doesn't update ModifiedBy
                #Set-PnPListItem -List $libName -Identity $_.Id -Connection $pnpConnect -Values @{"Editor"=$systemAccountMail;"Author"=$systemAccountMail} -UpdateType UpdateOverwriteVersion -Batch $batch #SystemUpdate doesn't update ModifiedBy
            }
            #Invoke-PnPBatch -Batch $batch
        }
    }
} 

Function CleanWebPermissions {
    Param ($roleAssignments) #$RoleAssignments = (Get-PnPWeb -Includes RoleAssignments).RoleAssignments

    $roleAssignments | Foreach-Object { Get-PnPProperty -ClientObject $_ -Property "RoleDefinitionBindings" } | Out-null
    $roleAssignments | Foreach-Object { Get-PnPProperty -ClientObject $_ -Property "Member" } | Out-null

    $sitePerms = @()
    foreach ($roleAss in $roleAssignments) { #GetPermissionsFromWeb
        $sitePerms += [PSCustomObject]@{
            MemberLoginName = $roleAss.Member.LoginName
            MemberType = $roleAss.Member.PrincipalType
            BindingRoleNames =  $roleAss.RoleDefinitionBindings.Name
        }
    }
    
    foreach($sitePerm in $sitePerms){ #Remove permissions from Web
        foreach ($bindingRoleName in $sitePerm.BindingRoleNames) {
            if($sitePerm.MemberType -eq "SharePointGroup"){
                Set-PnPWebPermission -Group $sitePerm.MemberLoginName -RemoveRole $bindingRoleName
            }else{
                Set-PnPWebPermission -User $sitePerm.MemberLoginName -RemoveRole $bindingRoleName
            }
        }
    }
}

Function CleanListPermissions {
    Param ($list) #$roleAssignments = $list.RoleAssignments
    $roleAssignments = $list.RoleAssignments
    $roleAssignments | Foreach-Object { Get-PnPProperty -ClientObject $_ -Property "RoleDefinitionBindings" } | Out-null
    $roleAssignments | Foreach-Object { Get-PnPProperty -ClientObject $_ -Property "Member" } | Out-null

    $listPerms = @()
    foreach ($roleAss in $roleAssignments) { #GetPermissionsFromWeb
        $listPerms += [PSCustomObject]@{
            MemberLoginName = $roleAss.Member.LoginName
            MemberType = $roleAss.Member.PrincipalType
            BindingRoleNames =  $roleAss.RoleDefinitionBindings.Name
        }
    }
    
    foreach($listPerm in $listPerms){ #Remove permissions from Web
        foreach ($bindingRoleName in $listPerm.BindingRoleNames) {
            if($listPerm.MemberType -eq "SharePointGroup"){
                Set-PnPListPermission -Identity $list.Title -Group $listPerm.MemberLoginName -RemoveRole $bindingRoleName
            }else{
                Set-PnPListPermission -Identity $list.Title -User $listPerm.MemberLoginName -RemoveRole $bindingRoleName
            }
        }
    }
}

# Function SetSystemAccountToAllFolders {
#     Param ($pnpConnect)
#     #$pnpConnect = $srcConnect

#     $systemAccountName = "Tenant O365 Admin"
#     $systemAccountMail = "msO365admin@tenant.onmicrosoft.com" #papasito@tenant.onmicrosoft.com
#     $modifiedDate = "2021-06-01 12:00:00 AM"

#     #$libNamesToProcess = Get-PnPList -Connection $pnpConnect | Where-Object { $_.ItemCount -gt 0 -and !$systemLibs.Contains($_.Title) } | Foreach-Object { $_.Title }
#     $libNamesToProcess = @("DocPoint")
#     foreach ($libName in $libNamesToProcess) { #$libName = $libNamesToProcess[0]
#         $allItems = @(Get-PnPListItem -PageSize 5000 -Connection $pnpConnect -List $libName | Where-Object { $_.FieldValues.Modified -ne $modifiedDate} )
        
#         Write-Host "Setting user account to $($allItems.Length) folder(s) in:" $libName
#         if($allItems.Length -gt 0){
#             # $allItems | Foreach-Object { 
#             #     Set-PnPListItem -List $libName -Identity $_.Id -Connection $pnpConnect -Values @{"Editor"=$systemAccountMail;"Author"=$systemAccountMail;"Modified"=$modifiedDate} -UpdateType UpdateOverwriteVersion | Out-Null #SystemUpdate doesn't update ModifiedBy
#             # }
#             foreach($item in $allItems | Get-Random -Count $allItems.length){
#                 Set-PnPListItem -List $libName -Identity $item.Id -Connection $pnpConnect -Values @{"Editor"=$systemAccountMail;"Author"=$systemAccountMail;"Modified"=$modifiedDate} -UpdateType UpdateOverwriteVersion | Out-Null #SystemUpdate doesn't update ModifiedBy
#             }
#         }
#     }
# } 