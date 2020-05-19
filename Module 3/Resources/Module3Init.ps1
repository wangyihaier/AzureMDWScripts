<#
.SYNOPSIS
  This script initializes an existing Azure Data Lake and Azure SQL DW in preparation for Module 3. Use this script if you haven't previously run Modules 1 and 2 of the Ready Lab

.DESCRIPTION
  This script copies the data that will be used for Polybase ingestion in Module 3 into the appropriate Azure Data Lake Blob containers. It also initializes the Azure SQL DW with appropriate logins and users

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
. ../../Scripts/Common/InitEnv.ps1


# ----------- Create loading user login in DW if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating 'loading user' login in data warehouse instance..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.sql_logins WHERE name = 'usgsloader') CREATE LOGIN usgsloader WITH PASSWORD = '$adminPassword'" -ServerInstance $fullyQualifiedServerName -Database "master" -Username $adminUser -Password $adminPassword

# ----------- Create loading user in DW if not already existing -------------------------------------------------------------------------------------------------
Write-Host "Creating loading user in data warehouse instance..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals WHERE name = 'usgsloader') CREATE USER usgsloader FOR LOGIN usgsloader" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ------------ Allocate more resources to loading users on data warehouse instance -------------------------------------------------------------------------
Write-Host "Adjusting resource allocation for loading users on data warehouse instance..."
Invoke-Sqlcmd -Query "IF NOT EXISTS(SELECT * FROM sys.database_principals princ JOIN sys.database_permissions perm on perm.grantee_principal_id = princ.principal_id WHERE name = 'usgsloader' AND permission_name = 'CONTROL') GRANT CONTROL ON DATABASE::[$dataWarehouseName] TO usgsloader" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword
Invoke-Sqlcmd -Query "EXEC sp_addrolemember 'staticrc60', 'usgsloader'" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $adminUser -Password $adminPassword

# ----------- Configured managed service identity access if not already existing -------------------------------------------------------------------------------------------------
$serverAzureAdIdentity = (Get-AzADServicePrincipal -SearchString $serverName).Id
if (!$serverAzureAdIdentity)
{
    Write-Host "Configuring managed service identity access to Azure Data Lake..."
    $StorageContributorRole = "Storage Blob Data Contributor"

    # Grant server access to data lake (requires Owner permissions)
    $subscriptionId = (Get-AzSubscription -SubscriptionName $subscriptionName).SubscriptionId
    $permissionScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$dataLakeName"

    echo $serverAzureAdIdentity
    echo $permissionScope
    New-AzRoleAssignment -ObjectId $serverAzureAdIdentity -RoleDefinitionName $StorageContributorRole -Scope $permissionScope > $null
}

# ------------ Upload weather and fire event files to Data Lake Store if not already existing -------------------------------------------------------------------------------
Write-Host "Checking weather and fire event files in Data Lake Store Gen2..."
Connect-AzAccount -Subscription $subscriptionName
$storageContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $dataLakeName).Context
$sourceStorageContext = New-AzureStorageContext -StorageAccountName 'sqldwexternaldata' -Anonymous -Protocol Https

# Check if blob containers exist
$fireEventsContainer = Get-AzStorageContainer -ResourceGroupName $resourceGroupName -StorageAccountName $dataLakeName -Name "fireevents" -ErrorAction SilentlyContinue
$weatherEventsContainer = Get-AzStorageContainer -ResourceGroupName $resourceGroupName -StorageAccountName $dataLakeName -Name "weatherevents" -ErrorAction SilentlyContinue

# Create fireevents container if not existing
if(!$fireEventsContainer)
{
    Write-Host "Creating 'fireevents' blob storage container ..."
    New-AzureStorageContainer -Name "fireevents" -Context $storageContext -Permission blob > $null
}

# Create weatherevents container if not existing
if(!$weatherEventsContainer)
{
    Write-Host "Creating 'weatherevents' blob storage container ..."
    New-AzureStorageContainer -Name "weatherevents" -Context $storageContext -Permission blob > $null
}

# Check if blob containers are empty
$factFireEventsBlob = Get-AzureStorageBlob -Context $storageContext -Container "fireevents" -Blob "dbo.factFireEvents.txt" -ErrorAction SilentlyContinue
$factWeatherEventsBlob = Get-AzureStorageBlob -Context $storageContext -Container "weatherevents" -Blob "QID59578_20190117_11449_10.txt" -ErrorAction SilentlyContinue

# Upload fireevents data if not existing
if (!$factFireEventsBlob)
{
    Write-Host "Copying 'firevents' data to Azure Data Lake ..."
    $fireEventsSourceContainer = (Get-AzureStorageContainer -Name 'ready2019fireevents' -Context $sourceStorageContext).CloudBlobContainer
    $fireEventsBlobs = Get-AzureStorageBlob -Context $sourceStorageContext -Container 'ready2019fireevents'
    foreach ($blob in $fireEventsBlobs)
    {
        Start-AzureStorageBlobCopy -Context $sourceStorageContext -CloudBlobContainer $fireEventsSourceContainer -SrcBlob $blob.Name -DestContainer 'fireevents' -DestContext $storageContext -DestBlob $blob.Name > $null
    }
}

# Upload weatherevents data if not existing
if (!$factWeatherEventsBlob)
{
    Write-Host "Copying 'weatherevents' data to Azure Data Lake ..."
    $weatherEventsSourceContainer = (Get-AzureStorageContainer -Name 'ready2019weatherevents' -Context $sourceStorageContext).CloudBlobContainer
    $weatherEventsBlobs = Get-AzureStorageBlob -Context $sourceStorageContext -Container 'ready2019weatherevents'
    foreach ($blob in $weatherEventsBlobs)
    {
        Start-AzureStorageBlobCopy -Context $sourceStorageContext -CloudBlobContainer $weatherEventsSourceContainer -SrcBlob $blob.Name -DestContainer 'weatherevents' -DestContext $storageContext -DestBlob $blob.Name > $null
    }
}

Write-Host "All resources initialized for module 3"
