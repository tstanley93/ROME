#Requires -Version 3.0

Param(
    [string] [Parameter(Mandatory=$true)] $srcUri,
	[string] [Parameter(Mandatory=$true)] $srcStorageAccount,
	[string] [Parameter(Mandatory=$true)] $srcStorageKey,
	[string] [Parameter(Mandatory=$true)] $containerName,
	[string] [Parameter(Mandatory=$true)] $vhdName,
	[string] [Parameter(Mandatory=$true)] $newResourceGroup,
	[string] [Parameter(Mandatory=$true)] $newResourceGroupLocation,
	[string] [Parameter(Mandatory=$true)] $DeploymentName,
	[string] [Parameter(Mandatory=$true)] $TemplateFilePath,
	[string] [Parameter(Mandatory=$true)] $ParameterFilePath
)

Set-StrictMode -Version 3
Import-Module Azure -ErrorAction SilentlyContinue

try {
    $AzureToolsUserAgentString = New-Object -TypeName System.Net.Http.Headers.ProductInfoHeaderValue -ArgumentList 'VSAzureTools', '1.4'
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.UserAgents.Add($AzureToolsUserAgentString)
} catch { }

$TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)
$ParameterFilePath = [System.IO.Path]::Combine($PSScriptRoot, $ParameterFilePath)

###Create a new Resource Group for Deployment
New-AzureResourceGroup -Name $newResourceGroup -Location $newResourceGroupLocation

###Create a new destination storage account
New-AzureStorageAccount -ResourceGroupName $newResourceGroup -Name $DeploymentName -Type Standard_LRS -Location $newResourceGroupLocation

### Get new destination storage account key
$destStorageKey= Get-AzureStorageAccountKey -ResourceGroupName $newResourceGroup -Name $DeploymentName

### Create the source storage account context ### 
$srcContext = New-AzureStorageContext  –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey 

### Create the destination storage account context ### 
$destContext = New-AzureStorageContext  –StorageAccountName $DeploymentName -StorageAccountKey $destStorageKey.Key1
 
### Create the container on the destination ### 
New-AzureStorageContainer -Name $containerName -Context $destContext 
 
### Start the asynchronous copy - specify the source authentication with -SrcContext ### 
$blob1 = Start-AzureStorageBlobCopy -srcUri $srcUri -SrcContext $srcContext -DestContainer $containerName -DestBlob $vhdName -DestContext $destContext

### Retrieve the current status of the copy operation ###
$status = $blob1 | Get-AzureStorageBlobCopyState 
 
### Loop until complete ###                                    
While($status.Status -eq "Pending"){
  $status = $blob1 | Get-AzureStorageBlobCopyState 
  Start-Sleep 10
  ### Print out status ###
  $status
}

#Begin the new deployment.
Switch-AzureMode AzureResourceManager

New-AzureResourceGroupDeployment -ResourceGroupName $newResourceGroup `
    -Name $DeploymentName `
    -TemplateFile $TemplateFilePath `
    -TemplateParameterFile $ParameterFilePath `
	-Force -Verbose
