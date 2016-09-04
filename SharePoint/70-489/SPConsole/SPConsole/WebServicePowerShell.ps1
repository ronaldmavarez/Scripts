
$searchApp = Get-SPEnterpriseSearchServiceApplication
$config = New-SPEnterpriseSearchContentEnrichmentConfiguration
$config.Endpoint = http://localhost:8080/SearchProcessor.svc
$config.InputProperties = "InputManagedProperty" //not crawled properties here
$config.OutputProperties = "OutputManagedProperty" //not crawled properties here
Set-SPEnterpriseSearchContentEnrichmentConfiguration -SearchApplication $searchApp -ContentEnrichmentConfiguration $config