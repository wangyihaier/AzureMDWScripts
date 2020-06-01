

<# 
# ----------- Pass-in the variables below to set session-wide variables that will be used later ---------------------------------------------------------
param (
    [Parameter(Mandatory=$true)] [string]$subscriptionId,
	[Parameter(Mandatory=$true)] [string]$resourceGroupName,
    [Parameter(Mandatory=$true)] [string]$participantNumber    
)
$ErrorActionPreference = "Stop"

$subscriptionId = 'b221e5a7-d112-44a3-9a93-4acc1457ad0a' 
$participantNumber = 123 
$resourceGroupName = 'wymoderndw' 

Connect-AzAccount -Subscription $subscriptionId

# ------- Setup module variables --------------------------
$serverName = 'usgsserver' + $participantNumber
$fullyQualifiedServerName = $serverName + '.database.windows.net'
$dataWarehouseName = 'usgsdataset'
$dataFactoryName = 'usgsdatafactory' + $participantNumber
$dataLakeName = 'usgsdatalake' + $participantNumber
$adminUser = 'usgsadmin'
$adminPassword = 'P@ssword' + $participantNumber   

$localUserPassword = "usgsP@ssword" + $participantNumber   
$localUserId = "usgsadmin"

$integrationRuntimeName = 'dataMovementEngine'
$dWConnectionString = "Server=tcp:$fullyQualifiedServerName,1433;Initial Catalog=$dataWarehouseName;User ID=$adminuser;Password=$adminPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$dwConnectionString_Secure = ConvertTo-SecureString -String $dwConnectionString -AsPlainText -Force
$localUserPassword_Secure = ConvertTo-SecureString -String $localUserPassword -AsPlainText -Force
$dataLakeAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $dataLakeName).Value[0] 
$dataLakeAccountKey_Secure = ConvertTo-SecureString -String $dataLakeAccountKey -AsPlainText -Force
$dataLakeURL = "https://$dataLakeName.dfs.core.windows.net"  

#>

. ..\..\Scripts\Common\InitEvn.ps1

# Create an integration runtime instance
Set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name 'dataMovementEngine' -Type SelfHosted -Description "Integration runtime to copy on-prem SQL Server data to cloud" 

# Retrieve integration runtime instance key
$AuthKeys = Get-AzDataFactoryV2IntegrationRuntimeKey -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name dataMovementEngine

# Install & Register Integration Runtime Gateway
.\gatewayInstall.ps1 $AuthKeys.AuthKey1

#----------------Grant acess to data lake for Data Factory 
# Get ServicePrincipalId assigend for Data Factory
# List details of the Storage Blob Data Contributor Role
$StorageContributorRole = "Storage Blob Data Contributor"
Get-AzRoleDefinition -Name $StorageContributorRole

$dataFactoryAzureAdIdentity = (Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $dataFactoryName ).Identity.PrincipalId
$permissionScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$dataLakeName"

$AssignedRoles= Get-AzRoleAssignment -ObjectId $dataFactoryAzureAdIdentity
if(-not $AssignedRoles)
{
     New-AzRoleAssignment -ObjectId $dataFactoryAzureAdIdentity -RoleDefinitionName $StorageContributorRole -Scope $permissionScope
}
else
{
    Write-Host "The role of " + $StorageContributorRole + "has assigend for the data factory:" + $dataFactoryName
}

$pipelineTemplateFile =  (Join-Path $PSScriptRoot "usgs_copypipeline_v2.0.json")

 New-AzResourceGroupDeployment -Name USGSPipelineDeployment -ResourceGroupName $resourceGroupName `
 -TemplateFile $pipelineTemplateFile `
 -dataFactoryName $dataFactoryName `
 -integrationRuntimeName $integrationRuntimeName `
 -cloudDWConnectionString $dwConnectionString_Secure `
 -dataLakeURL $dataLakeURL `
 -localFileSystemPassword $localUserPassword_Secure `
 -localUserId $localUserId `
 -localServerName $env:computername
# New-AzResourceGroupDeployment -Name USGSPipelineDeployment -ResourceGroupName $resourceGroupName -TemplateFile $pipelineTemplateFile  -TemplateParameterObject $templateParametersValues

# Manually trigger pipeline
$pipelineRunId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -PipelineName "USGSInitialCopy" 


# Monitor pipeline status

Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -PipelineRunId $pipelineRunId 
