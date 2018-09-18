#Run with the farm account. 

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#Any web application associated with SSS proxy application or central admin
$WebAppURL="http://SP2016.contoso.com"

#Establish the Context
$Provider = New-Object Microsoft.Office.SecureStoreService.Server.SecureStoreProvider
$Provider.Context =  Get-SPServiceContext -Site $WebAppURL

#Get All Target Applications
$TargetApps = $provider.GetTargetApplications()
foreach ($App in $TargetApps)
{
    Write-Output $App.Name
    
    #Get the credentials for the App
    $Credentials = $provider.GetCredentials($App.Name)
    foreach ($Cred in $Credentials)
    {
        $EncryptString  = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Credential)
        $DecryptString  = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($EncryptString)
        
        Write-Output "$($cred.CredentialType): $($DecryptString)"
    }
}