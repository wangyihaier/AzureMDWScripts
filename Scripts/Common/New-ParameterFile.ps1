param (
    [string] $Path = (Join-Path $PSScriptRoot "azuredeploy.json"),
    [switch] $OnlyMandatoryParameter,
    [switch] $NonInteractive
)

class ParameterFile {
    # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-parameter-files
    [string] $schema = "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
    [string] $contenVersion = "1.0.0.0"
    [hashtable] $parameters
    
    ParameterFile ([array]$Parameters) {
        foreach ($Parameter in $Parameters) {
            $this.parameters += @{
                $Parameter.name = @{
                    value = "Prompt"
                }
            }
        }
    }

    ParameterFile ([array]$Parameters, [array]$ParametersVals) {

        $i=0
        foreach ($Parameter in $Parameters) {
            $this.parameters += @{
                $Parameter.name = @{
                    value = $ParametersVals[$i]
                }
            }
            # Write-Host "Index:"+$i+": "+$Parameter
            $i++
          
        }
    }

    ParameterFile ( [hashtable]$ParametersVals) {

       $this.parameters = $ParametersVals
    }
}

class ParameterFileGenerator {
    
    $Template
    $Parameter
    $MandatoryParameter
    $ParameterValue
    
    ParameterFileGenerator ($Path) {
        $this.Template = $this._loadTemplate($Path)
        $this.Parameter = $this._getParameter($this.Template)
        $this.MandatoryParameter = $this._getMandatoryParameterByParameter($this.Parameter)
    }

    ParameterFileGenerator ($Path,$ParaVal) {
        $this.Template = $this._loadTemplate($Path)
        $this.Parameter = $this._getParameter($this.Template)
        $this.MandatoryParameter = $this._getMandatoryParameterByParameter($this.Parameter)
        $this.ParameterValue = $ParaVal
    }
    
    [PSCustomObject] _loadTemplate($Path) {
        Write-Verbose "Read from $Path"
        # Test for template presence
        $null = Test-Path $Path -ErrorAction Stop

        # Test if arm template content is readable
        $TemplateContent = Get-Content $Path -Raw -ErrorAction Stop
        Write-Verbose "Template Content `n $TemplateContent"

        # Convert the ARM template to an Object
        return ConvertFrom-Json $TemplateContent -ErrorAction Stop
    }

    [Array] _getParameter($Template) {
        # Extract the Parameters properties from JSON
        $ParameterObjects = $Template.Parameters.PSObject.Members | Where-Object MemberType -eq NoteProperty

        $Parameters = @()
        foreach ($ParameterObject in $ParameterObjects) {
            $Key = $ParameterObject.Name
            $Property = $ParameterObject.Value
    
            $Property | Add-Member -NotePropertyName "Name" -NotePropertyValue $Key
            $Parameters += $Property
            Write-Verbose "Parameter Found $Key"
        }
        return $Parameters
    }

    [Array] _getMandatoryParameterByParameter($Parameter) {
        return $Parameter | Where-Object {
            $null -eq $_.defaultValue 
        }
    }
    
    [ParameterFile] GenerateParameterFile([boolean] $OnlyMandatoryParameter) {
        if ($OnlyMandatoryParameter) {
            return [ParameterFile]::new($this.MandatoryParameter,$this.ParameterValue) 
        }
        else {
            return [ParameterFile]::new($this.ParameterValue) 
        }
       
    }

}

function New-ParameterFile {
    <#
    .SYNOPSIS
    Creats a parameter file json based on a given ARM tempalte
    
    .DESCRIPTION
    Creats a parameter file json based on a given ARM tempalte
    
    .PARAMETER Path
    Path to the ARM template, by default searches the script path for a "azuredeploy.json" file
    
    .PARAMETER OnlyMandatoryParameter
    Creates parameter file only with Mandatory Parameters ("defaultValue") not present
    
    .EXAMPLE
    New-ParameterFile
    {
        "schema":  "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
        "contenVersion":  "1.0.0.0",
        "parameters":  {
            "...":  {
                "value":  null
                            },
            "...":  {
                "value":  null
            }
    }
    
    .EXAMPLE
    New-ParameterFile -OnlyMandatoryParameter
    {
        "schema":  "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
        "contenVersion":  "1.0.0.0",
        "parameters":  {
            "...":  {
                "value":  null
                            },
            "...":  {
                "value":  null
            }
    }
    
    .EXAMPLE
    New-ParameterFile -Path $Path -OnlyMandatoryParameter
    {
        "schema":  "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
        "contenVersion":  "1.0.0.0",
        "parameters":  {
            "...":  {
                "value":  null
                            },
            "...":  {
                "value":  null
            }
    }
    #>
    
    
    [CmdletBinding()]
    param (
        [string] $Path = (Join-Path $PSScriptRoot "azuredeploy.json"),
        [string] $ParametersFilePath = (Join-Path $PSScriptRoot "azuredeploy-parameters.json"),
        [hashtable] $ParameterValues = @{val1="val1";val2="val2"},
        [switch] $OnlyMandatoryParameter,
        [switch] $SaveToFile
    )
    
    begin {
        
    }
    
    process {
        if($SaveToFile)
        {
            [ParameterFileGenerator]::new($Path,$ParameterValues).GenerateParameterFile($OnlyMandatoryParameter) | ConvertTo-Json > $ParametersFilePath 
        }
        else
        {
            [ParameterFileGenerator]::new($Path,$ParameterValues).GenerateParameterFile($OnlyMandatoryParameter) | ConvertTo-Json
        }
    }
    
    end {
        
    }
}


if ($NonInteractive) {
    New-ParameterFile 
}