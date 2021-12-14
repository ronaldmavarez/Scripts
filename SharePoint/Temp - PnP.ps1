# Set an anchor to a metadata field, Term Set Setting 
Connect-PnPOnline -Url https://my.sharepoint.com/sites/yoursite
$field = Get-PnPField -List "ListName" -Identity "FieldName"
[Microsoft.SharePoint.Client.Taxonomy.TaxonomyField] $taxonomyFld = [Microsoft.SharePoint.Client.ClientContext].GetMethod("CastTo").MakeGenericMethod([Microsoft.SharePoint.Client.Taxonomy.TaxonomyField]).Invoke($field.Context, $field)
$taxonomyFld.TermSetId = '00000000-0000-0000-0000-000000000000'
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