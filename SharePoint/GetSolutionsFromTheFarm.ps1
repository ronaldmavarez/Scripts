$directory = "c:\temp\" #make sure the path exist or you have access
#$solutionNames = @("Solution1.wsp", "Solution2.wsp", "Solution3.wsp") #write the name of the solutions you need
$solutionNames = ""

Write-Host Exporting solutions to $directory  

#When looking for specifics solutions
if ($solutionNames.length -gt 0){ 
	$farm = Get-SPFarm
	foreach ($solutionName in $solutionNames) {
		if($farm.Solutions.Item($solutionName)){
			$solution = $farm.Solutions.Item($solutionName)
			$title = $solution.Name  
			$filename = $solution.SolutionFile.Name 
			
			Write-Host "Exporting ‘$title’ as …\$filename"
			
			try {  
				$solution.SolutionFile.SaveAs("$directory\$filename")  
			}  
			catch  
			{  
				Write-Host " – error : $_" -foreground red  
			}  
		}
	}
	
	Write-Host "Exported all the WSP specified and found in server" -foreground green
}else { #When looking for all he solutions in the server
	
	foreach ($solution in Get-SPSolution)  {   
		$title = $solution.Name  
		$filename = $solution.SolutionFile.Name 
		
		Write-Host "Exporting ‘$title’ as …\$filename"

		try {  
			$solution.SolutionFile.SaveAs("$directory\$filename")  
		}  
		catch  
		{  
			Write-Host " – error : $_" -foreground red  
		}  
	}
	
	Write-Host "Exported all the WSP found in the server" -foreground green
}