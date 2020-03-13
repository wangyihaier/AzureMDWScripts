<#
.SYNOPSIS
  This script sets up the local SQL Server Instance with logins and data required to complete the SQL Data Warehouse workshop.
#>

$adminPassword = ConvertTo-SecureString "P@ssword00" -AsPlainText -Force
$adminCredential = New-Object System.Management.Automation.PSCredential('usgsadmin',$adminPassword)
$currentUser = "$env:computername\usgsadmin"

# Remove vestigial admin logins
Write-Output "Removing vestigial admin login..."
$admin0 = "usgsvm00\usgsadmin"
$admin106 = "usgsvm106\usgsadmin"
$admin0Exists = Invoke-SqlCmd -Query "SELECT * FROM sys.syslogins WHERE loginname = '$admin0'" -ServerInstance $env:computername -Database "master" -Credential $adminCredential -ErrorAction SilentlyContinue
$admin106Exists = Invoke-SqlCmd -Query "SELECT * FROM sys.syslogins WHERE loginname = '$admin106'" -ServerInstance $env:computername -Database "master" -Credential $adminCredential -ErrorAction SilentlyContinue
if ($adminExists)
{
    Remove-SqlLogin -ServerInstance $env:computername -LoginName "usgsvm00\usgsadmin" -Credential $adminCredential -RemoveAssociatedUsers -Force -ErrorAction SilentlyContinue
}
if ($admin106Exists)
{
    Remove-SqlLogin -ServerInstance $env:computername -LoginName "usgsvm106\usgsadmin" -Credential $adminCredential -RemoveAssociatedUsers -Force -ErrorAction SilentlyContinue
}

# Add current user login if not exists
$userExists = Invoke-SqlCmd -Query "SELECT * FROM sys.syslogins WHERE loginname = '$currentUser'" -ServerInstance $env:computername -Database "master" -Credential $adminCredential -ErrorAction SilentlyContinue
if (!$userExists)
{
    Write-Output "Adding current user as sql server admin..."
    Add-SqlLogin -ServerInstance $env:computername -LoginName $currentUser -LoginType "WindowsUser" -Credential $adminCredential -Enable -GrantConnectSql -ErrorAction SilentlyContinue
    Invoke-SqlCmd -Query "ALTER SERVER ROLE sysadmin ADD MEMBER [$currentUser]" -ServerInstance $env:computername -Database "master" -Credential $adminCredential
}
Write-Output "[$currentUser] added as SQL Server admin"

# Restore SQL Database if not exists
$dbExists = Get-SqlDatabase -Name "fireEvents" -ServerInstance $env:computername -ErrorAction SilentlyContinue
if (!$dbExists)
{
    Write-Output "Restoring SQL database..."
    $backupFilePath = "C:\USGSData\fireevents.bak"
    Invoke-SqlCmd -Query "RESTORE DATABASE fireEvents FROM DISK = '$backupFilePath'" -Database "master" -Credential $adminCredential -QueryTimeout 130
}
Write-Output "fireEvents database restored"

