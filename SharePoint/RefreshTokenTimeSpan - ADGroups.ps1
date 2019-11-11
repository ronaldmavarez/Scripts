<#
The tokens have a lifetime (by default 10 hours). More than that, SharePoint by default will cache the AD security group membership details for 24 hours. That means, once the SharePoint will get the details for a security group, if the AD security group will change, SharePoint will still use the cache.

When your access in SharePoint rely on the AD security groups you have to adjust the caching mechanism for the tokens and you have to adjust it properly everywhere (SharePoint and STS).

I am not sure if 2 minutes will create some performance issues, need to be tested
#>

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