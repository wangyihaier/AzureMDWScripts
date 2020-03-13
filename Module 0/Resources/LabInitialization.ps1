<#
.SYNOPSIS
  This script initializes the SQL Data Warehouse created for the Ready 2019 workshop with required users and logins
#>

# ----------- Pass-in the variables below to set session-wide variables that will be used later ---------------------------------------------------------
param (
    [Parameter(Mandatory=$true)] [string]$subscriptionName,
	[Parameter(Mandatory=$true)] [string]$resourceGroupName,
    [Parameter(Mandatory=$true)] [string]$participantNumber    
)
$ErrorActionPreference = "Stop"

# Configure Azure Resource Manager template variables that will be used session-wide
$serverName = 'usgsserver' + $participantNumber
$fullyQualifiedServerName = $serverName + '.database.windows.net'
$dataWarehouseName = 'usgsdataset'
$dataLakeName = 'usgsdatalake' + $participantNumber
$adminUser = 'usgsadmin'
$adminPassword = 'P@ssword' + $participantNumber
$californiaEmployeePassword = $californiaManagerPassword = $texasEmployeePassword = $texasManagerPassword = $adminPassword    #Not best practice. Done here for simplicity

# ------------ Create logins on master database  -------------------------------------------------------------------------
Write-Host "Creating logins on master database..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.sql_logins WHERE name = 'CaliforniaForestryEmployee') CREATE LOGIN CaliforniaForestryEmployee WITH PASSWORD = '$californiaEmployeePassword'" -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.sql_logins WHERE name = 'CaliforniaForestryManager') CREATE LOGIN CaliforniaForestryManager WITH PASSWORD =  '$californiaManagerPassword'" -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.sql_logins WHERE name = 'TexasForestryEmployee') CREATE LOGIN TexasForestryEmployee WITH PASSWORD =  '$texasEmployeePassword'" -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.sql_logins WHERE name = 'TexasForestryManager') CREATE LOGIN TexasForestryManager WITH PASSWORD = '$texasManagerPassword'" -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.sql_logins WHERE name = 'usgsloader') CREATE LOGIN usgsloader WITH PASSWORD = '$adminPassword'" -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword

# ------------ Create users based on logins on master database -------------------------------------------------------------------------
Write-Host "Creating users based on logins on master database..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'CaliforniaForestryEmployee') CREATE USER CaliforniaForestryEmployee FOR LOGIN CaliforniaForestryEmployee " -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'CaliforniaForestryManager') CREATE USER CaliforniaForestryManager FOR LOGIN CaliforniaForestryManager " -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'TexasForestryEmployee') CREATE USER TexasForestryEmployee FOR LOGIN TexasForestryEmployee " -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'TexasForestryManager') CREATE USER TexasForestryManager FOR LOGIN TexasForestryManager " -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'usgsloader') CREATE USER usgsloader FOR LOGIN usgsloader " -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword

# ------------ Create users based on logins on data warehouse instance -------------------------------------------------------------------------
Write-Host "Creating users on data warehouse instance..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'CaliforniaForestryEmployee') CREATE USER CaliforniaForestryEmployee FOR LOGIN CaliforniaForestryEmployee " -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'CaliforniaForestryManager') CREATE USER CaliforniaForestryManager FOR LOGIN CaliforniaForestryManager " -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'TexasForestryEmployee') CREATE USER TexasForestryEmployee FOR LOGIN TexasForestryEmployee " -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'TexasForestryManager') CREATE USER TexasForestryManager FOR LOGIN TexasForestryManager " -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'usgsloader') CREATE USER usgsloader FOR LOGIN usgsloader" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * from sys.database_principals WHERE name = 'employee') CREATE ROLE employee" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * from sys.database_principals WHERE name = 'manager') CREATE ROLE manager" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ------------ Assign users to db_datareader role -------------------------------------------------------------------------
Write-Host "Assigning users to reader role..."
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'db_datareader', 'CaliforniaForestryEmployee'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'db_datareader', 'CaliforniaForestryManager'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'db_datareader', 'TexasForestryEmployee'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'db_datareader', 'TexasForestryManager'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ------------ Assign users to manager/employee roles -------------------------------------------------------------------------------
Write-Host "Assigning users to manager/employee roles..."
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'employee', 'CaliforniaForestryEmployee'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'manager', 'CaliforniaForestryManager'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'employee', 'TexasForestryEmployee'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'manager', 'TexasForestryManager'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ------------ Allocate more resources to loading users on data warehouse instance -------------------------------------------------------------------------
Write-Host "Adjusting resource allocation for loading users on data warehouse instance..."
Invoke-Sqlcmd -Query "GRANT CONTROL ON DATABASE::[$dataWarehouseName] TO usgsloader" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'staticrc60', 'usgsloader'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ------------ Copy welcome message to Data Lake Store -------------------------------------------------------------------------------
Write-Host "Uploading test message to Data Lake Store Gen2..."
Connect-AzAccount -Subscription $subscriptionName
$storageContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $dataLakeName).Context

$containerName = "readme"
$blobName = "readme.txt"
try 
{
    Get-AzStorageBlob -Container $containerName -Blob $blobName -Context $storageContext -ErrorAction Stop
}
catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException]
{
    New-AzStorageContainer -Name $containerName -Context $storageContext -Permission Blob > $null
    Set-AzStorageBlobContent -File "$PSScriptRoot\readme.txt" -Container $containerName -Blob $blobName -Context $storageContext
}
catch
{
    # Report any other error
    Write-Error $Error[0].Exception;
}
