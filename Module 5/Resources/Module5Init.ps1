<#
.SYNOPSIS
  This script initializes an existing Azure Data Lake and Azure SQL DW in preparation for Module 5. Use this script if you haven't previously run Modules 1, 2, 3, and 4 of the Ready Lab

.DESCRIPTION
  This script creates external staging tables, and production distributed tables in the SQL DW. It also initializes the DW with appropriate logins and users

#>

<#
# ----------- Pass-in the variables below to set session-wide variables that will be used later ---------------------------------------------------------
param (
    [Parameter(Mandatory=$true)] [string]$subscriptionName,
    [Parameter(Mandatory=$true)] [string]$participantNumber,    
    [Parameter(Mandatory=$true)] [string]$resourceGroupName 
)
$ErrorActionPreference = "Stop"
$serverName = 'usgsserver' + $participantNumber
$fullyQualifiedServerName = $serverName + '.database.windows.net'
$dataWarehouseName = 'usgsdataset'
$dataLakeName = 'usgsdatalake' + $participantNumber
$adminUser = 'usgsadmin'
$adminPassword = 'P@ssword' + $participantNumber
#>

. ..\..\Scripts\Common\InitEnv.ps1

# ----------- Create loading user login in DW if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating loading user login in data warehouse instance if not present..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.sql_logins WHERE name = 'usgsloader') CREATE LOGIN usgsloader WITH PASSWORD = '$adminPassword'" -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword

# ----------- Create loading user in DW if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating loading user in data warehouse instance if not present..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'usgsloader') CREATE USER usgsloader FOR LOGIN usgsloader" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ------------ Allocate more resources to loading users on data warehouse instance -------------------------------------------------------------------------
Write-Host "Adjusting resource allocation for loading users on data warehouse instance..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals princ JOIN sys.database_permissions perm on perm.grantee_principal_id = princ.principal_id WHERE name = 'usgsloader' AND permission_name = 'CONTROL') GRANT CONTROL ON DATABASE::[$dataWarehouseName] TO usgsloader" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'staticrc60', 'usgsloader'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ----------- Create CaliforniaForestryEmployee user login in DW if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating 'CaliforniaForestryEmployee' user login if not present..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.sql_logins WHERE name = 'CaliforniaForestryEmployee') CREATE LOGIN CaliforniaForestryEmployee WITH PASSWORD = '$adminPassword'" -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword

# ----------- Create CaliforniaForestryEmployee user in DW if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating 'CaliforniaForestryEmployee' user in data warehouse instance if not present..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'CaliforniaForestryEmployee') CREATE USER CaliforniaForestryEmployee FOR LOGIN CaliforniaForestryEmployee" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'db_datareader', 'CaliforniaForestryEmployee'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ----------- Create CaliforniaForestryManager user login in DW if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating 'CaliforniaForestryManager' user login if not present..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.sql_logins WHERE name = 'CaliforniaForestryManager') CREATE LOGIN CaliforniaForestryManager WITH PASSWORD = '$adminPassword'" -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword

# ----------- Create CaliforniaForestryManager user in DW if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating 'CaliforniaForestryManager' user in data warehouse instance if ont present..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'CaliforniaForestryManager') CREATE USER CaliforniaForestryManager FOR LOGIN CaliforniaForestryManager" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'db_datareader', 'CaliforniaForestryManager'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ----------- Create weatherevents external data source if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating 'weatherevents' external data source if not present..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(select * from sys.external_data_sources WHERE name = 'usgsweatherevents') CREATE EXTERNAL DATA SOURCE USGSWeatherEvents WITH (TYPE = HADOOP, LOCATION = 'wasbs://ready2019weatherevents@sqldwexternaldata.blob.core.windows.net');" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ----------- Create fireevents external data source if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating 'fireevents' external data source if not present..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(select * from sys.external_data_sources WHERE name = 'usgsfireevents') CREATE EXTERNAL DATA SOURCE USGSFireEvents WITH (TYPE = HADOOP, LOCATION = 'wasbs://ready2019fireevents@sqldwexternaldata.blob.core.windows.net');" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ----------- Create CSV external file format if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating CSV text file format if not present..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(select * from sys.external_file_formats WHERE name = 'TextFileFormat') CREATE EXTERNAL FILE FORMAT TextFileFormat WITH (FORMAT_TYPE = DELIMITEDTEXT, FORMAT_OPTIONS(FIELD_TERMINATOR = '|') );" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ----------- Create staging and production schemas if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating staging and production schemas..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(select * from sys.schemas WHERE name = 'EXT') EXEC sp_executesql N'CREATE SCHEMA EXT';" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(select * from sys.schemas WHERE name = 'STG') EXEC sp_executesql N'CREATE SCHEMA STG';" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "IF NOT EXISTS(select * from sys.schemas WHERE name = 'PROD') EXEC sp_executesql N'CREATE SCHEMA PROD';" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ----------- Create external tables if none exist -------------------------------------------------------------------------------------------------
$tblCount = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS tblCount FROM sys.external_tables" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword).tblCount
if (!$tblCount)
{
    Write-Host "Creating external tables in data warehouse instance..."
    Invoke-Sqlcmd -InputFile "$PSScriptRoot\..\..\Module 3\Resources\CreateExternalTables.sql" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
}

# ----------- Create distributed tables if none exist -------------------------------------------------------------------------------------------------
$tblCount = (Invoke-Sqlcmd -Query "SELECT COUNT(*) AS tblCount FROM sys.tables tbls JOIN sys.schemas schemas on tbls.schema_id = schemas.schema_id WHERE schemas.name = 'PROD'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword).tblCount
if (!$tblCount)
{
    Write-Host "Creating distributed tables in data warehouse instance..."
    Invoke-Sqlcmd -InputFile "$PSScriptRoot\..\..\Module 4\Resources\CreateDistributedTables.sql" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword -QueryTimeout 300
}

Write-Host "All resources initialized for module 5"
