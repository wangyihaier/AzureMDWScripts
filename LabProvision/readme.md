
# Deployment Guide 


## Lab Environment Provisioning

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/
https%3a%2f%2fraw.githubusercontent.com%2fwangyihaier%2fAzureMDWScripts%2fmaster%2fBeforeLab%2fDWLabDeployment.json" target="_blank">
    <img src="../images/deploytoazure.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3a%2f%2fraw.githubusercontent.com%2fwangyihaier%2fAzureMDWScripts%2fmaster%2fBeforeLab%2fDWLabDeployment.json" target="_blank">
    <img src="../images/visualizebutton.png"/>
</a>

### <span style="color:red"> The Azure image used here requires the permission to access. Please drop me a mail at [Wangyihaier](mailto:wangyihaier@yahoo.com?subject=ADWLab%20Image%20Request) </span>



This template allows you to deploy a basic Azure Modern Data Warehouse referene achitecture under the same resource group in which includes:

<ul>
<li>On-premise file server and SQL Server</li>
<li>Azure Data Factory</li>
<li>Azure Data Lake Storage Gen2</li>
<li>Azure Synapse (formaly Azure Data Warehouse)</li>
</ul>


## Login to Azure VM

The provisioned Azure VM comes pre-installed with the client tools you will need to complete lab modules: Azure PowerShell, SQL Server Management Studio (SSMS), Azure Storage Explorer, SQL Server, Azure Data Factory on-prem runtime instance. To login using a Remote Desktop Session, use the credentials below -making sure to replace ‘##’ with the userNumber you used for deployment:

<ul>
<li>VM Username: \usgsadmin</li>
<li>VM Password: usgsP@ssword##<li>
</ul>


