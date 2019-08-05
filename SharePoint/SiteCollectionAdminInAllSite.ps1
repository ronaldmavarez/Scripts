Add-PSSnapin *sharepoint*
#Install the module
#Install-Module -Name CredentialManager
#Create the credentials using the line below
#New-StoredCredential -Target "PnPCredentials" -UserName "UserName" -Password "UserPassword"

$cred = Get-StoredCredential -Target "PnPCredentials"

$url = "https://SharePointURL"
$userToAdd = "c:0+.w|s-1-5-21-3619852530-2710989942-2557074336-12345" #SID

Connect-PnPOnline $url -Credentials $cred
$SiteCollections = Get-SPWebApplication $mysiteURL | Get-SPSiteAdministration -Limit ALL | Select URL
foreach ($SiteCollection in $SiteCollections)
{
    Write-Host $SiteCollection.Url
    Connect-PnPOnline -Url $SiteCollection.Url -Credentials $cred
    Add-PnPSiteCollectionAdmin -Owners $userToAdd
    #Get-PnPSiteCollectionAdmin 
}