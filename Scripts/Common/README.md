# Common Scripts

## Environment Variables Initialization (InitEnv.ps1)

This script is used to do Azure login and initialize the global variables at the beginning of each module script. The values of these variables are stored in the Key Vault instance as the secrets. Therefore, this script will have 2 main responsibilities:

**Azure Login**

```powershell

function Login($SubId) {
    $context = Get-AzContext

    if (!$context -or ($context.Subscription.Id -ne $SubId)) {
        Connect-AzAccount -Subscription $SubId
    } 
    else {
        Write-Host "SubscriptionId '$SubId' already connected"
    }
}
Login -SubId $subscriptionId

```

**Assign the secrets to the global variables**

1. The Key Valut instance and the secrets are created while provisioning this lab using the ARM tempalte. The details could be found at LabProvision/DWLabDeployment.json.

    ```json
    <!-- language: json -->
    "secrets": [
                    {
                        "secretName": "[variables('administratorLoginPasswordSecretName')]",
                        "secretValue": "[variables('administratorLoginPassword')]"
                    },
                    {
                        "secretName": "[variables('virtualMachinePasswordSecretName')]",
                        "secretValue": "[variables('virtualMachinePassword')]"
                    },
                    {
                        "secretName": "[variables('usgsServerSecretName')]",
                        "secretValue": "[variables('usgsServer')]"
                    },
                    {
                        "secretName": "[variables('locationSecretName')]",
                        "secretValue": "[variables('location')]"
                    },
                    {
                        "secretName": "[variables('administratorLoginSecretName')]",
                        "secretValue": "[variables('administratorLogin')]"
                    },
                    {
                        "secretName": "[variables('datawarehouseNameSecretName')]",
                        "secretValue": "[variables('datawarehouseName')]"
                    },
                    {
                        "secretName": "[variables('virtualMachineNameSecretName')]",
                        "secretValue": "[variables('virtualMachineName')]"
                    },
                    {
                        "secretName": "[variables('vnetNameSecretName')]",
                        "secretValue": "[variables('vnetName')]"
                    },
                    {
                        "secretName": "[variables('subnetNameSecretName')]",
                        "secretValue": "[variables('subnetName')]"
                    },
                    {
                        "secretName": "[variables('dataFactoryNameSecretName')]",
                        "secretValue": "[variables('dataFactoryName')]"
                    },
                    {
                        "secretName": "[variables('dataLakeNameSecretName')]",
                        "secretValue": "[variables('dataLakeName')]"
                    },
                    {
                        "secretName": "[variables('stagingAccountNameSecretName')]",
                        "secretValue": "[variables('stagingAccountName')]"
                    },
                    {
                        "secretName": "[variables('networkInterfaceNameSecretName')]",
                        "secretValue": "[variables('networkInterfaceName')]"
                    },
                    {
                        "secretName": "[variables('publicIpAddressNameSecretName')]",
                        "secretValue": "[variables('publicIpAddressName')]"
                    },
                    {
                        "secretName": "[variables('networkSecurityGroupNameSecretName')]",
                        "secretValue": "[variables('networkSecurityGroupName')]"
                    },
                    {
                        "secretName": "[variables('adbWorkspaceNameSecretName')]",
                        "secretValue": "[variables('adbWorkspaceName')]"
                    },
                    {
                        "secretName": "[variables('managedResourceGroupNameSecretName')]",
                        "secretValue": "[variables('managedResourceGroupName')]"
                    }
                ]

    ```

    2. Access the Key Vault and retrive the values

    
        ```powershell

        function RetriveSecrets() 
        {
            param(
                [string]
                [Parameter(Mandatory,HelpMessage='Enter the key vault name')]
                $keyVaultName = 'usgskv123',
                [string]
                [Parameter(Mandatory,HelpMessage='Enter the secret name')]
                $secretName
            )

            if(-not(Get-AzKeyVault -VaultName $keyVaultName ))
            {
                Write-Host "Key Vault '$keyVaultName' does not exist"
                break
            }
        
            return (Get-AzKeyVaultSecret -vaultName $keyVaultName -name $secretName).SecretValueText
        }

        $serverName = RetriveSecrets -keyVaultName $keyVaultName -secretName 'usgsserverSecretName'
        $fullyQualifiedServerName = $serverName + '.database.windows.net'
        $dataWarehouseName = RetriveSecrets -keyVaultName $keyVaultName -secretName 'datawarehouseNameSecretName'
        $dataFactoryName = RetriveSecrets -keyVaultName $keyVaultName -secretName 'dataFactoryNameSecretName'
        $dataLakeName = RetriveSecrets -keyVaultName $keyVaultName -secretName 'dataLakeNameSecretName'
        $adminUser = RetriveSecrets -keyVaultName $keyVaultName -secretName 'administratorLoginSecretName'
        $adminPassword = RetriveSecrets -keyVaultName $keyVaultName -secretName 'administratorLoginPasswordSecretName'

        $dataLakeAccountName = $dataLakeName
        $virtualNetworkName = RetriveSecrets -keyVaultName $keyVaultName -secretName 'vnetNameSecretName' #'usgsvirtualnetwork' + $participantNumber
        $subNetName = RetriveSecrets -keyVaultName $keyVaultName -secretName 'subnetNameSecretName' #'usgsSubnet' 
        $dbUserName = $adminUser
        $dbPassword = $adminPassword
        $securePasswordString = ConvertTo-SecureString $dbPassword -AsPlainText -Force
        $dbCredentials = New-Object System.Management.Automation.PSCredential($dbUserName, $securePasswordString)
        $dataFactoryName = RetriveSecrets -keyVaultName $keyVaultName -secretName 'dataFactoryNameSecretName'

        $localUserPassword = RetriveSecrets -keyVaultName $keyVaultName -secretName 'virtualMachinePasswordSecretName'
        $localUserId = $adminUser

        $integrationRuntimeName = 'dataMovementEngine'
        $dWConnectionString = "Server=tcp:$fullyQualifiedServerName,1433;Initial Catalog=$dataWarehouseName;User ID=$adminuser;Password=$adminPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
        $dwConnectionString_Secure = ConvertTo-SecureString -String $dwConnectionString -AsPlainText -Force
        $localUserPassword_Secure = ConvertTo-SecureString -String $localUserPassword -AsPlainText -Force
        $dataLakeAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $dataLakeName).Value[0] 
        $dataLakeAccountKey_Secure = ConvertTo-SecureString -String $dataLakeAccountKey -AsPlainText -Force
        $dataLakeURL = "https://$dataLakeName.dfs.core.windows.net"  
        ```