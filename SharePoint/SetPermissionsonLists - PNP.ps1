$siteURL = "https://tenant.sharepoint.com/sites/RonaldPostMigTest"
Connect-PnPOnline -Url $siteURL -Interactive 

$mappingInfo = @(
    [PSCustomObject]@{ #SourceLib: Common Activities Restricted - Destination Library: Common Activities
        LibName = "Documents";
        Assigments = @(
            [pscustomobject]@{SPGroupName='RonaldPostMigTest Members';PermRoleDef='Edit'}
            [pscustomobject]@{SPGroupName='RonaldPostMigTest Visitors';PermRoleDef='Edit'}
            [pscustomobject]@{SPGroupName='RonaldPostMigTest Owners';PermRoleDef='Read'}
        )
    }
)

$rolDefs = Get-PnPRoleDefinition | Foreach-Object { $_.Name }

foreach($objMain in $mappingInfo){
    #we have to remove the users manually because the one who runs the script remains 
    Set-PnPList -Identity $objMain.LibName -ResetRoleInheritance
    Set-PnPList -Identity $objMain.LibName -BreakRoleInheritance -ClearSubscopes 

    $spUsers = Get-PnPUser
    foreach($spUser in $spUsers){ #remove the users
        $listPerm = Get-PnPListPermissions -Identity $objMain.LibName -PrincipalId $spUser.Id
        if($listPerm){
            $rolDefs | Foreach-Object { Set-PnPListPermission -Identity $objMain.LibName -User $spUser.LoginName -RemoveRole $_ -ErrorAction SilentlyContinue  }
        }
    }

    $spGroups = Get-PnPGroup
    foreach($spGroup in $spGroups){ #remove the users
        $listPerm = Get-PnPListPermissions -Identity $objMain.LibName -PrincipalId $spGroup.Id
        if($listPerm){
            $rolDefs | Foreach-Object { Set-PnPListPermission -Identity $objMain.LibName -Group $spGroup -RemoveRole $_ -ErrorAction SilentlyContinue  }
        }
    }

    #set the permissions 
    foreach($assigment in $objMain.Assigments){
        #Write-Host $assigment
        $adGroup = Get-PnPGroup -Identity $assigment.SPGroupName
        Set-PnPListPermission -Identity $objMain.LibName -Group $adGroup -AddRole $assigment.PermRoleDef
    }
}

Disconnect-PnPOnline