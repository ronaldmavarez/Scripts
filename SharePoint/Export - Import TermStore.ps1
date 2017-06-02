Connect-PnPOnline -Url $siteURL -Credentials Get-Credential
Export-PnPTermGroupToXml -Out "C:\WinniePooh\Desktop\TermStore.xml"
Import-PnPTermGroupFromXml -Path "C:\WinniePooh\Desktop\TermStore.xml"