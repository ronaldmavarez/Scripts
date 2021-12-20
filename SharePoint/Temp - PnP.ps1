# Set an anchor to a metadata field, Term Set Setting 
Connect-PnPOnline -Url https://my.sharepoint.com/sites/yoursite
$field = Get-PnPField -List "ListName" -Identity "FieldName"
[Microsoft.SharePoint.Client.Taxonomy.TaxonomyField] $taxonomyFld = [Microsoft.SharePoint.Client.ClientContext].GetMethod("CastTo").MakeGenericMethod([Microsoft.SharePoint.Client.Taxonomy.TaxonomyField]).Invoke($field.Context, $field)
$taxonomyFld.TermSetId  = '00000000-0000-0000-0000-000000000000' #The parent node
$taxonomyFld.AnchorId   = '00000000-0000-0000-0000-000000000000' #The child node where the document starts
$taxonomyFld.UpdateAndPushChanges($true)
Invoke-PnPQuery

# Move-SPOFolder $folderSourceURL $folderTargetURL
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

#Set permissions to documents with unique permissions
$listItemsAll = @(Get-PnPListItem -List $libName -Fields "DocumentType", "DocType", "_dlc_DocIdUrl", "FileDirRef", "FileRef", "Title", "GUID" -Connection $pnpConnect -PageSize 5000)

#Loading properties from a list item
$items = Get-PnPListItem -List "RonaldTest"
$items | Foreach-Object { Get-PnPProperty -ClientObject $_ -Property "HasUniqueRoleAssignments" } | Out-null

#Get list items with special fields
$listName = "RonaldTest"
$siteURL = "https://tenant.sharepoint.com/sites/123456"
$pnpConnect = Connect-PnPOnline -Url $siteURL -Interactive -ReturnConnection
$items = Get-PnPListItem -List $listName  -Fields "HasUniqueRoleAssignments"


$items = Get-PnPListItem -List $listName
$items | Foreach-Object { Get-PnPProperty -ClientObject $_ -Property @("HasUniqueRoleAssignments", "RoleAssignments") } | Out-null
$uniqueRoleItems = $items | Where-Object { $_.HasUniqueRoleAssignments -eq $true }

$uniqueRoleItems.RoleAssignments | ForEach-Object { Get-PnPProperty -ClientObject $_ -Property @("RoleDefinitionBindings") | Out-null }

$uDoc = $uniqueRoleItems[0]

foreach ($rolAss in $uDoc.RoleAssignments) { #$rolAss = $uDoc.RoleAssignments[0]
    Get-PnPProperty -ClientObject $rolAss -Property "Member" | Out-null

    if($rolAss.Member.PrincipalType -eq "User") {
        $loginId = $rolAss.Member.Email
        $rolAss.RoleDefinitionBindings | Foreach-Object { Set-PnPListItemPermission -List $listName -Identity $uDoc.Id -User $loginId -RemoveRole $_.Name }
        Set-PnPListItemPermission -List $listName -Identity $uDoc.Id -User $loginId -AddRole "Read"
    }elseif ($rolAss.Member.PrincipalType -eq "SharePointGroup") {
        $loginId = $rolAss.Member.Id
        $rolAss.RoleDefinitionBindings | Foreach-Object { Set-PnPListItemPermission -List $listName -Identity $uDoc.Id -Group $loginId -RemoveRole $_.Name }
        Set-PnPListItemPermission -List $listName -Identity $uDoc.Id -Group $loginId -AddRole "Read"
    }
}