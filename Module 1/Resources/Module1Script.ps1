$subscriptionName = 'b221e5a7-d112-44a3-9a93-4acc1457ad0a' 
$participantNumber = 123 
$resourceGroupName = 'wymoderndw'

Connect-AzAccount -Subscription $SubscriptionName

$serverName = 'usgsserver' + $participantNumber
$fullyQualifiedServerName = $serverName + '.database.windows.net'
$dataWarehouseName = 'usgsdataset'
$dataFactoryName = 'usgsdatafactory' + $participantNumber
$dataLakeName = 'usgsdatalake' + $participantNumber
$adminUser = 'usgsadmin'
$adminPassword = 'P@ssword' + $participantNumber   


Set-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name 'dataMovementEngine' -Type SelfHosted -Description "Integration runtime to copy on-prem SQL Server data to cloud" 


Get-AzDataFactoryV2IntegrationRuntimeKey -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -Name dataMovementEngine


$localUserPassword = "usgsP@ssword" + $participantNumber   
$localUserId = "usgsadmin"

$integrationRuntimeName = 'dataMovementEngine'
$dWConnectionString = "Server=tcp:$fullyQualifiedServerName,1433;Initial Catalog=$dataWarehouseName;User ID=$adminuser;Password=$adminPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$dwConnectionString_Secure = ConvertTo-SecureString -String $dwConnectionString -AsPlainText -Force
$localUserPassword_Secure = ConvertTo-SecureString -String $localUserPassword -AsPlainText -Force
$dataLakeAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $dataLakeName).Value[0] 
$dataLakeAccountKey_Secure = ConvertTo-SecureString -String $dataLakeAccountKey -AsPlainText -Force
$dataLakeURL = "https://$dataLakeName.dfs.core.windows.net"  


New-AzResourceGroupDeployment -Name USGSPipelineDeployment -ResourceGroupName $resourceGroupName -TemplateFile "C:\USGSdata\loadingtemplates\usgs_copypipeline.json" -dataFactoryName $dataFactoryName -integrationRuntimeName $integrationRuntimeName -cloudDWConnectionString $dwConnectionString_Secure -dataLakeURL $dataLakeURL -dataLakeAccountKey $dataLakeAccountKey_Secure -localFileSystemPassword $localUserPassword_Secure -localUserId $localUserId -localServerName $env:computername


# Manually trigger pipeline
$pipelineRunId = Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -PipelineName "USGSInitialCopy" 


# Monitor pipeline status
Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -PipelineRunId $pipelineRunId 
