# ----------- Pass-in the variables below to set session-wide variables that will be used later ---------------------------------------------------------
param (
    [Parameter(Mandatory = $true)] [string]$subscriptionId,
    [Parameter(Mandatory = $true)] [string]$resourceGroupName,
    [Parameter(Mandatory = $true)] [string]$participantNumber    
)
$ErrorActionPreference = "Stop"


function Login($SubId) {
    $context = Get-AzContext

    if (!$context -or ($context.Subscription.Id -ne $SubId)) {
        Connect-AzAccount -Subscription $SubId
    } 
    else {
        Write-Host "SubscriptionId '$SubId' already connected"
    }
}

function RegisterKeyVault() 
{
    param(
        [string]
        $keyVaultName = 'usgskv123',
        [string]
        $resourceGroupName='wymd',
        [string]
        $location = 'southeastasia',
        [string[]]
        $keyVaultAdminUsers = @('wyia@microsoft.com'),
        [Parameter(Mandatory=$false)]
        [Switch]$EnabledForDiskEncryption,
        [Parameter(Mandatory=$false)]
        [Switch]$EnabledForDeployment,
        [Parameter(Mandatory=$false)]
        [Switch]$EnabledForTemplateDeployment
    )

 
    # Make the Key Vault provider is available
    Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault

    # Create the Resource Group
    Get-AzResourceGroup -Name $resourceGroupName  -Location $location -ErrorVariable notPresent -ErrorAction SilentlyContinue
    if($notPresent)
    {
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }
    else
    {
        Write-Host "Resource Group '$resourceGroupName' has existed"
    }

    # Create the Key Vault (enabling it for Disk Encryption, Deployment and Template Deployment)
    Get-AzKeyVault -VaultName $keyVaultName  -ErrorVariable notPresent -ErrorAction SilentlyContinue
    if($notPresent)
    {
        New-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -Location $location `
        -EnabledForDiskEncryption -EnabledForDeployment -EnabledForTemplateDeployment
    }
    else
    {
        Write-Host "Key Vault '$keyVaultName' has existed"
    }

    # Add the Administrator policies to the Key Vault
    foreach ($keyVaultAdminUser in $keyVaultAdminUsers) {
        Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -UserPrincipalName $keyVaultAdminUser `
            -PermissionsToKeys decrypt, encrypt, unwrapKey, wrapKey, verify, sign, get, list, update, create, import, delete, backup, restore, recover, purge `
            -PermissionsToSecrets get, list, set, delete, backup, restore, recover, purge `
            -PermissionsToCertificates get, list, delete, create, import, update, managecontacts, getissuers, listissuers, setissuers, deleteissuers, manageissuers, recover, purge, backup, restore
    }
}



function AssignSecretPermissions() 
{
    param(
        [string]
        $keyVaultName = 'usgskv123',
        [string]
        $resourceGroupName='wymd',
        [string]
        $keyVaultUser = 'wangyihaier@outlook.com',
        [string[]]
        $permissions = ('get','list')
    )

   
    if(-not(Get-AzKeyVault -VaultName $keyVaultName ))
    {
        Write-Host "Key Vault '$keyVaultName' does not exist"
        break
    }

    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -UserPrincipalName $keyVaultUser `
            -PermissionsToSecrets $permissions
  }


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

# The name of the Azure subscription to install the Key Vault into
# $subscriptionId = 'b221e5a7-d112-44a3-9a93-4acc1457ad0a'

# The resource group that will contain the Key Vault to create to contain the Key Vault
# $resourceGroupName = 'wymd'

# The name of the Key Vault to install
$keyVaultName = 'usgskv' + $participantNumber 

Login -SubId $subscriptionId

AssignSecretPermissions -keyVaultName $keyVaultName -resourceGroupName $resourceGroupName -keyVaultUser (Get-AzContext).Account.Id

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
