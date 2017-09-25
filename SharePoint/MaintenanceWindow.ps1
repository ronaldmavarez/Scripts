Add-PSSnapin *sharepoint*

$maintenanceStartDate  = "8/01/2017 06:00:00 PM" # Date when the maintenance will start
$maintenanceEndDate    = "8/01/2017 11:00:00 PM" # Date when the maintenance will stop
$notificationStartDate = "7/30/2017 06:00:00 AM" # Date when the message will start being displayed
$notificationEndDate   = "8/01/2017 11:30:00 PM" # Date when the message will stop being displayed
$maintenanceLink       = ""                      # This link will only appear if the maintenance duration is defined.
$maintenanceType       = "MaintenancePlanned"    # OPTIONS ARE: MaintenancePlanned | MaintenanceWarning
$readOnlyDays          = 0   # duration days
$readOnlyHours         = 0   # duration hours. 
$readOnlyMinutes       = 0   # duration minutes only appears if days and minutes are both zero


$maintenanceWindow = New-Object Microsoft.SharePoint.Administration.SPMaintenanceWindow
$maintenanceWindow.MaintenanceEndDate    = $maintenanceEndDate
$maintenanceWindow.MaintenanceStartDate  = $maintenanceStartDate
$maintenanceWindow.NotificationEndDate   = $notificationEndDate
$maintenanceWindow.NotificationStartDate = $notificationStartDate
$maintenanceWindow.MaintenanceType       = $maintenanceType
$maintenanceWindow.Duration              = New-Object System.TimeSpan( $readOnlyDays, $readOnlyHours, $readOnlyMinutes, 0)
$maintenanceWindow.MaintenanceLink       = $maintenanceLink

Get-SPContentDatabase | % {
    $_.MaintenanceWindows.Clear()
    $_.MaintenanceWindows.Add($maintenanceWindow)
    $_.Update()
} 
