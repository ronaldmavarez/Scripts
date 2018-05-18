Add-PSSnapin *sharepoint*

$wa = Get-SPWebApplication http://webAppUrl
$adsearchobj = New-Object Microsoft.SharePoint.Administration.SPPeoplePickerSearchActiveDirectoryDomain
$adsearchobj.DomainName = "contoso.com"
$adsearchobj.ShortDomainName = "CONTOSO" #Optional
$adsearchobj.IsForest = $true #$true for Forest, $false for Domain

$wa.PeoplePickerSettings.SearchActiveDirectoryDomains.Add($adsearchobj)
$wa.Update()