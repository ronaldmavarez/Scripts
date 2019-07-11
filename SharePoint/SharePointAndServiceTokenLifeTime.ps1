Add-PSSnapin Microsoft.SharePoint.PowerShell;
 
$CS = [Microsoft.SharePoint.Administration.SPWebService]::ContentService;
#TokenTimeout value before
$CS.TokenTimeout;
$CS.TokenTimeout = (New-TimeSpan -minutes 2);
#TokenTimeout value after
$CS.TokenTimeout;
$CS.update();
 
$STSC = Get-SPSecurityTokenServiceConfig
#WindowsTokenLifetime value before
$STSC.WindowsTokenLifetime;
$STSC.WindowsTokenLifetime = (New-TimeSpan -minutes 2);
#WindowsTokenLifetime value after
$STSC.WindowsTokenLifetime;
#FormsTokenLifetime value before
$STSC.FormsTokenLifetime;
$STSC.FormsTokenLifetime = (New-TimeSpan -minutes 2);
#FormsTokenLifetime value after
$STSC.FormsTokenLifetime;
#LogonTokenCacheExpirationWindow value before
$STSC.LogonTokenCacheExpirationWindow;
#DO NOT SET LogonTokenCacheExpirationWindow LARGER THAN WindowsTokenLifetime
$STSC.LogonTokenCacheExpirationWindow = (New-TimeSpan -minutes 1);
#LogonTokenCacheExpirationWindow value after
$STSC.LogonTokenCacheExpirationWindow;
$STSC.Update();
IISRESET