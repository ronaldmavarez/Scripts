
$cred = Get-Credential
$adGroupSID = 'c:0+.w|s-1-5-21-295751396-2062643724-1150087556-12826'
$addRole = $true

Connect-PnPOnline https://WebApp/ -TenantAdminUrl https://WebApp/sites/admin -Credentials $cred
$siteCollectionss = Get-PnPTenantSite
foreach ($siteCollections in $siteCollectionss)
{
    Write-Host $siteCollections.Url
    Connect-PnPOnline -Url $siteCollections.Url -Credentials $cred

    if($addRole){
        Set-PnPWebPermission -User $adGroupSID -AddRole "Contribute"
    }else{
        Set-PnPWebPermission -User $adGroupSID -RemoveRole "Contribute"
    }    

    $recSubWebs = Get-PnPSubWebs -Recurse -Includes HasUniqueRoleAssignments
    foreach ($subWeb in $recSubWebs){
       if ($subWeb.HasUniqueRoleAssignments){
            $subWeb.Url
            if($addRole){
                Set-PnPWebPermission -Web $subWeb -User $adGroupSID -AddRole "Contribute"
            }else{
                Set-PnPWebPermission -Web $subWeb -User $adGroupSID -RemoveRole "Contribute"
            }   
       }
    }
    
    Disconnect-PnPOnline
} 
