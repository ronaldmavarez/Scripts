#Azure Apps
#Note: Not optimized at all, pending to do

Connect-PnPOnline -Url "https://tenant.sharepoint.com" -Interactive
$azureApps = Get-PnPAzureADApp

$infos = @(); $perms2Check = @()
$whatAPI2Ignore = @("AppId", "DisplayName")

$templateAppURL = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/#AppID/isMSAApp~/false"

foreach($azureApp in $azureApps){
    $azurePerm = Get-PnPAzureADAppPermission -Identity $azureApp.AppId
    $propNames = @(($azurePerm | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" -and !$whatAPI2Ignore.Contains($_.Name)}).Name) | Where-Object { ![string]::IsNullOrEmpty($_) }
    
    if($propNames.Count -eq 0){
        continue
    }

    $info = $azureApp.DisplayName + " (" + ($propNames -join ', ') + ")" 
    Write-Host $info

    $perms = @()
    foreach($entity in $propNames){ #$entity = $propNames[0]
        if($entity -eq "MicrosoftGraph"){
            $perms += $azurePerm.MicrosoftGraph
        }
        if($entity -eq "SharePoint"){
            $perms += $azurePerm.SharePoint
        }
    }
    
    $relevantPerms = @($perms | Where-Object { ($_.IndexOf("Write") -gt 0 -or $_.IndexOf("Full") -gt 0) -and ![string]::IsNullOrEmpty($_) })
    if($relevantPerms.Count -gt 0){
        $otherPerms = $perms | Where-Object { !$relevantPerms.Contains($_) }
        #Write-Host "Name: $($azureApp.DisplayName) ID: $($azureApp.AppId) ($($perms -join '; '))"
        $infos += [PSCustomObject]@{
            AppID = $azureApp.AppId
            AppName = $azureApp.DisplayName
            API = $propNames -join ' -- '
            RelevantPerm = $relevantPerms -join ' -- '
            OtherPerm = $otherPerms -join ' -- '
            Status = "NotChecked"
            AppURL = $templateAppURL.Replace("#AppID", $azureApp.AppId)
        }
    }
}

$filePath = "C:\TEMP\AzureAppSPOPermissions.csv"
$infos | Export-Csv $filePath -NoTypeInformation -Encoding UTF8 -Delimiter ';'

<#
#SharePoint Roles
AllSites.FullControl
AllSites.Manage
AllSites.Read
AllSites.Write
EnterpriseResource.Read
EnterpriseResource.Write
MyFiles.Read
MyFiles.Write
Project.Read
Project.Write
ProjectWebApp.FullControl
ProjectWebAppReporting.Read
Sites.Search.All
Sites.FullControl.All
TaskStatus.Submit
TermStore.Read.All
TermStore.ReadWrite.All
User.Read.All
User.ReadWrite.All


Sites.ReadWrite.All
#>
