<#
.SYNOPSIS
  This script initializes an existing Azure Data Lake and Azure SQL DW in preparation for Module 3. Use this script if you haven't previously run Modules 1 and 2 of the Ready Lab

.DESCRIPTION
  This script copies the data that will be used for Polybase ingestion in Module 3 into the appropriate Azure Data Lake Blob containers. It also initializes the Azure SQL DW with appropriate logins and users

#>

#
. '..\..\Module 0\Resources\LabInitialization.ps1'

. '..\..\Module 0\Resources\USGS_LabBootstrap.ps1'

. '..\..\Module 1\Resources\Module1Script.ps1'

. '..\..\Module 2\Resources\Module2Script.ps1'

Write-Host "All resources initialized for module 3"
