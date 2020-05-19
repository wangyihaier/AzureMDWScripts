
<#
$subscriptionId = 'b221e5a7-d112-44a3-9a93-4acc1457ad0a' 
$participantNumber = 123 
$resourceGroupName = 'wydw'

Connect-AzAccount -Subscription $subscriptionId

# --------------- Setup module variables ---------------------------------- 
$serverName = 'usgsserver' + $participantNumber 
$dataLakeAccountName = 'usgsdatalake' + $participantNumber
$dataWarehouseName = 'usgsdataset'
$virtualNetworkName = 'usgsvirtualnetwork' + $participantNumber
$subNetName = 'usgsSubnet' 
$dbUserName = 'usgsadmin';
$dbPassword = 'P@ssword' + $participantNumber
$securePasswordString = ConvertTo-SecureString $dbPassword -AsPlainText -Force
$dbCredentials = New-Object System.Management.Automation.PSCredential($dbUserName, $securePasswordString)
$dataFactoryName = 'usgsdatafactory' + $participantNumber
#>

. ../../Scripts/Common/InitEnv.ps1

#----------------Restrict global access to Azure Data Lake Storage instance
# Display the default rule for the data lake
(Get-AzStorageAccountNetworkRuleSet -ResourceGroupName $resourceGroupName -AccountName $dataLakeAccountName).DefaultAction

# Configure network rules to deny access by default
Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -DefaultAction Deny 


# Configure network rules to allow access from trusted Microsoft services and logging pipelines
Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName -Name $DataLakeAccountName -Bypass AzureServices,Metrics,Logging 

#----------------Create managed-service identity for your Azure SQL Data Warehouse
# Generate and assign an Azure AD Identity for this server
Set-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $serverName -AssignIdentity 


# List details of the Storage Blob Data Contributor Role
$StorageContributorRole = "Storage Blob Data Contributor"
Get-AzRoleDefinition -Name $StorageContributorRole

# Get ServicePrincipalId assigned to SQL Server
$serverAzureAdIdentity = (Get-AzADServicePrincipal -SearchString $ServerName).Id

# Grant server access to data lake (requires Owner permissions)
# $subscriptionId = (Get-AzSubscription -SubscriptionName $subscriptionName).SubscriptionId
# $subscriptionId = $subscriptionName
$permissionScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName"
New-AzRoleAssignment -ObjectId $serverAzureAdIdentity -RoleDefinitionName $StorageContributorRole -Scope $permissionScope


# Create external table to read test message in data lake
$databaseCredentialQuery = "CREATE MASTER KEY; CREATE DATABASE SCOPED CREDENTIAL readme_cred WITH IDENTITY = 'Managed Service Identity';"
$externalDataSourceQuery = "CREATE EXTERNAL DATA SOURCE [usgsdatalakereadme] WITH (TYPE=HADOOP, LOCATION=N'abfss://readme@$dataLakeAccountName.dfs.core.windows.net', CREDENTIAL = readme_cred)"
$externalFileFormatQuery = "CREATE EXTERNAL FILE FORMAT [usgsdatalakereadmeformat] WITH (FORMAT_TYPE = DELIMITEDTEXT, FORMAT_OPTIONS (FIELD_TERMINATOR = N'|', USE_TYPE_DEFAULT = False))"
$externalTableQuery = "CREATE EXTERNAL TABLE [staging].[dataLakeAccessTest]([header] [nvarchar](40) NOT NULL,[notice] [nvarchar](150) NOT NULL)
WITH (DATA_SOURCE = [usgsdatalakereadme],LOCATION = N'/readme.txt',FILE_FORMAT = [usgsdatalakereadmeformat],REJECT_TYPE = VALUE,REJECT_VALUE = 0)"
Invoke-Sqlcmd -Query "CREATE schema staging" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $dbCredentials.UserName -Password $dbCredentials.GetNetworkCredential().Password
Invoke-Sqlcmd -Query $databaseCredentialQuery -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $dbCredentials.UserName -Password $dbCredentials.GetNetworkCredential().Password
Invoke-Sqlcmd -Query $externalDataSourceQuery -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $dbCredentials.UserName -Password $dbCredentials.GetNetworkCredential().Password
Invoke-Sqlcmd -Query $externalFileFormatQuery -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $dbCredentials.UserName -Password $dbCredentials.GetNetworkCredential().Password
Invoke-Sqlcmd -Query $externalTableQuery -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $dbCredentials.UserName -Password $dbCredentials.GetNetworkCredential().Password

# Issue data warehouse query to test access to data lake storage instance.
Invoke-Sqlcmd -Query "SELECT * FROM staging.dataLakeAccessTest" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $dbCredentials.UserName -Password $dbCredentials.GetNetworkCredential().Password 


#----------------Grant acess to data lake for Data Factory 
# Get ServicePrincipalId assigend for Data Factory
$dataFactoryAzureAdIdentity = (Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $dataFactoryName ).Identity
$permissionScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$dataLakeAccountName"
New-AzRoleAssignment -ObjectId $dataFactoryAzureAdIdentity -RoleDefinitionName $StorageContributorRole -Scope $permissionScope


#--------------Add Azure Data Lake Storage to Virtual Network
# Get existing virtual network
$vnetInstance = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName

# Configure virtual network goal state
$subnetConfig = Set-AzVirtualNetworkSubnetConfig -Name $subNetName -VirtualNetwork $vnetInstance -AddressPrefix "10.0.0.0/24" -ServiceEndpoint "Microsoft.Storage"

# Enable service endpoint for Azure storage service on virtual network subnet
Set-AzVirtualNetwork -VirtualNetwork $subnetConfig 


# Add virtual network rule to data lake instance
$subnetInstance = Get-AzVirtualNetworkSubnetConfig -Name $subNetName -VirtualNetwork $vnetInstance
Add-AzStorageAccountNetworkRule -ResourceGroupName $resourceGroupName -Name $dataLakeAccountName -VirtualNetworkResourceId $subnetInstance.Id 

# Issue data warehouse query to test access to data lake storage instance. This query succeeds because the data warehouse uses managed service identity authentication
Invoke-Sqlcmd -Query "SELECT * FROM staging.dataLakeAccessTest" -ServerInstance $fullyQualifiedServerName -Database $dataWarehouseName -Username $dbCredentials.UserName -Password $dbCredentials.GetNetworkCredential().Password 


#-------------------Add SQL Data Warehouse instance to virtual network
# Configure virtual network goal state
$subnetConfig = Set-AzVirtualNetworkSubnetConfig -Name $subNetName -VirtualNetwork $vnetInstance -AddressPrefix "10.0.0.0/24" -ServiceEndpoint "Microsoft.Sql"

# Enable service endpoint for Azure SQL Server on existing virtual network subnet
Set-AzVirtualNetwork -VirtualNetwork $subnetConfig 
 
# Add virtual network rule to SQL Server instance
$subnetInstance = Get-AzVirtualNetworkSubnetConfig -Name $subNetName -VirtualNetwork $vnetInstance
New-AzSqlServerVirtualNetworkRule -ResourceGroupName $resourceGroupName -ServerName $serverName -VirtualNetworkRuleName $subNetName -VirtualNetworkSubnetId $subnetInstance.Id  

