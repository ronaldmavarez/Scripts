$siteURL = ""
$spListName = ""
$outputFilePath = "c:\Output.txt"

$spWeb = Get-SPWeb -Identity $siteURL
$spList = $spWeb.Lists[$spListName]

$spList.EventReceivers | Select Name, Assembly, Type | Out-File -filePath $outputFilePathFilePath -append
$eventsCount = $spList.EventReceivers.Count

for ($i = 0; $i -lt $eventsCount; $i++)
{ 
	"Printing the value for the event receiver: $i"  | Out-File -filePath $outputFilePath -append
	
	$spList.EventReceivers[$i].Name  | Out-File -filePath $outputFilePath -append
	$spList.EventReceivers[$i].Class | Out-File -filePath $outputFilePath -append
	$spList.EventReceivers[$i].Assembly | Out-File -filePath $outputFilePath -append
	
	"----------------------------------------------" | Out-File -filePath $outputFilePath -append
	"----------------------------------------------" | Out-File -filePath $outputFilePath -append
	"----------------------------------------------" | Out-File -filePath $outputFilePath -append
	" " | Out-File -filePath $outputFilePath -append
}
$spWeb.dispose()