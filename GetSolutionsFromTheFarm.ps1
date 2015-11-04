#SharePoint script for get the solutions from the farm or Central Administration, you name it.

[void][reflection.assembly]::Loadwithpartialname("Microsoft.SharePoint") | out-null
$directory = "c:\temp\" #make sure the path exist or you have access
$solutionNames = @("ActivationDependencyFix.wsp", "CodeContratcsPrerequisites.wsp", "Statoil.Imr.CorrespondanceLog.wsp", "Statoil.Imr.ProjectInfo.wsp", "Statoil.Imr.RiskAssessment.wsp") #write the name of the solutions you need

$farm = Get-SPFarm
foreach ($solutionName in $solutionNames) {
	$file = $farm.Solutions.Item($solutionName).SolutionFile
	$file.SaveAs($directory + $solutionName)
}