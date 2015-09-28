Param(
  [string] [Parameter(Mandatory=$true)] $ResourceGroupLocation,
  [string] [Parameter(Mandatory=$true)]$ResourceGroupName,
  [string] $TemplateFile = '..\Templates\Azure_BIG-IP_Deployment.json',
  [string] $TemplateParametersFile = '..\Templates\Azure_BIG-IP_Deployment.parameters.json'
)




#Read the JSON Parameter file
$json= (Get-Content $TemplateParametersFile) -join "`n" | ConvertFrom-Json

###Create a new Resource Group for Deployment
New-AzureResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation

###Create a new destination storage account
New-AzureStorageAccount -ResourceGroupName $ResourceGroupName -Name $json.parameters.newStorageAccountName.value -Type Standard_LRS -Location $ResourceGroupLocation

### Get new destination storage account key
$destStorageKey= Get-AzureStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $json.parameters.newStorageAccountName.value

### Create the source storage account context ### 
$srcContext = New-AzureStorageContext  –StorageAccountName "bigipv12606best" -StorageAccountKey "yGGWNx8bwxQRkg3mOlPwevLTCu/GcVsKg9Ya4+SipQXccAItlBrAYARzv7l5qicyQt2Eb7lLm3hkfFzSnJ6fcQ==" 

### Create the destination storage account context ### 
$destContext = New-AzureStorageContext  –StorageAccountName $json.parameters.newStorageAccountName.value -StorageAccountKey $destStorageKey.Key1
 
### Create the container on the destination ### 
New-AzureStorageContainer -Name $json.parameters.newStorageAccountName.value -Context $destContext 
 
### Start the asynchronous copy - specify the source authentication with -SrcContext ### 
$blob1 = Start-AzureStorageBlobCopy -srcUri "https://bigipv12606best.blob.core.windows.net/bigipv12606best/bigipv12606best.vhd" -SrcContext $srcContext -DestContainer $json.parameters.newStorageAccountName.value -DestBlob ($json.parameters.newStorageAccountName.value + '.vhd') -DestContext $destContext

### Retrieve the current status of the copy operation ###
$status = $blob1 | Get-AzureStorageBlobCopyState 
 
### Loop until complete ###                                    
While($status.Status -eq "Pending"){
  $status = $blob1 | Get-AzureStorageBlobCopyState 
  Start-Sleep 10
  ### Print out status ###
  #$status
  Write-Progress -Activity "Copying vhd" -PercentComplete ($status.BytesCopied/$status.TotalBytes*100)
}