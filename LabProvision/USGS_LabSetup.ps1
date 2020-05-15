<#
.SYNOPSIS
  This script sets up and installs the tools and data required to complete the SQL Data Warehouse workshop.
#>

$adminPassword = ConvertTo-SecureString "P@ssword00" -AsPlainText -Force
$adminCredential = New-Object System.Management.Automation.PSCredential('usgsadmin',$adminPassword)
$currentUser = "$env:computername\usgsadmin"
$sharedDataFolder = "USGSData"
$sharedDataPath = "C:\USGSData"

# Add current user login
Write-Output "Adding current user as sql server admin..." | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
$userExists = Invoke-SqlCmd -Query "SELECT * FROM sys.syslogins WHERE loginname = '$currentUser'" -ServerInstance $env:computername -Database "master" -Credential $adminCredential -ErrorAction SilentlyContinue
if (!$userExists)
{
    Add-SqlLogin -ServerInstance $env:computername -LoginName $currentUser -LoginType "WindowsUser" -Credential $adminCredential -Enable -GrantConnectSql -ErrorAction SilentlyContinue *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    Invoke-SqlCmd -Query "ALTER SERVER ROLE sysadmin ADD MEMBER [$currentUser]" -ServerInstance $env:computername -Database "master" -Credential $adminCredential
}

# Restore SQL Database
$dbExists = Get-SqlDatabase -Name "fireEvents" -ServerInstance $env:computername -ErrorAction SilentlyContinue
if (!$dbExists)
{
    Write-Output "Restoring SQL database..." | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    $backupFilePath = "C:\USGSData\fireevents.bak"
    Invoke-SqlCmd -Query "RESTORE DATABASE fireEvents FROM DISK = '$backupFilePath'" -Database "master" -Credential $adminCredential -QueryTimeout 130 *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
}
Write-Output "fireEvents database restored" | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append

# Remove vestigial admin login
Write-Output "Removing vestigial admin login..." | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
Remove-SqlLogin -ServerInstance $env:computername -LoginName "usgsvm00\usgsadmin" -Credential $adminCredential -RemoveAssociatedUsers -Force -ErrorAction SilentlyContinue *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
Remove-SqlLogin -ServerInstance $env:computername -LoginName "usgsvm106\usgsadmin" -Credential $adminCredential -RemoveAssociatedUsers -Force -ErrorAction SilentlyContinue *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
Remove-SqlLogin -ServerInstance $env:computername -LoginName "usgsvm605\usgsadmin" -Credential $adminCredential -RemoveAssociatedUsers -Force -ErrorAction SilentlyContinue *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append


# Share the data folder
$sharedFolderExists = Get-SmbShare -Name $sharedDataFolder  -ErrorAction SilentlyContinue
if($sharedFolderExists)
{
    Remove-SmbShare -Name $sharedDataFolder -Force
}
if ( Test-Path -Path $sharedDataPath -PathType Container ) 
{
    New-SMBShare –Name $sharedDataFolder –Path  $sharedDataPath –FullAccess $currentUser 
}
        
# Add trusted Microsoft authentication sites to Internet Explorer
Write-Output "Adding trusted Microsoft auth sites to Internet Explorer" | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
Set-location -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains"

# Add https://login.microsoftonline.com
if (-not (Test-Path -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\microsoftonline.com\login'))
{
    Write-Output "Adding login.microsoftonline..." | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    New-Item -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\microsoftonline.com\login' -Force *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\microsoftonline.com\login' -Name https -Value 2 -Type DWord *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
}
# Add aadcdn.msauth.net
if (-not (Test-Path -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\msauth.net\aadcdn'))
{
    Write-Output "Adding aadcdn.msauth" | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    New-Item -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\msauth.net\aadcdn' -Force *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\msauth.net\aadcdn' -Name https -Value 2 -Type DWord *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
}
# Add aadcdn.msftauth.net
if (-not (Test-Path -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\msftauth.net\aadcdn'))
{
    Write-Output "Adding aadcdn.msftauth" | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    New-Item -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\msftauth.net\aadcdn' -Force *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\msftauth.net\aadcdn' -Name https -Value 2 -Type DWord *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
}
# Add https://msft.sts.microsoft.com
if (-not (Test-Path -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\microsoft.com\msft.sts'))
{
    Write-Output "Adding msft.sts" | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    New-Item -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\microsoft.com\msft.sts' -Force *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\microsoft.com\msft.sts' -Name https -Value 2 -Type DWord *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
}
# Add https://az416426.vo.msecnd.net
if (-not (Test-Path -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\msecnd.net\az416426.vo'))
{
    Write-Output "Adding az416426" | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    New-Item -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\msecnd.net\az416426.vo' -Force *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\msecnd.net\az416426.vo' -Name https -Value 2 -Type DWord *>&1 | Out-File -FilePath "C:\USGSData\SetupScripts\setuplog.txt" -Append
}

