#Requires -Version 3.0

Param(
  [string] $TemplateFile = '..\Templates\Azure_BIG-IP_Deployment_v2.json',
  [string] $TemplateParametersFile = '..\Templates\DeploymentTemplate.param.dev.json'
)

Set-StrictMode -Version 3
Import-Module Azure -ErrorAction SilentlyContinue
Add-AzureAccount
Switch-AzureMode AzureResourceManager

try {
    $AzureToolsUserAgentString = New-Object -TypeName System.Net.Http.Headers.ProductInfoHeaderValue -ArgumentList 'VSAzureTools', '1.4'
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.UserAgents.Add($AzureToolsUserAgentString)
} catch { }

$TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)
$TemplateParametersFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile)
$ResourceGroupLocation= Read-Host -Prompt "Please enter the new resource group location, e.g. West US"
$ResourceGroupName= Read-Host -Prompt "Please enter the name of the new resource group"
#$srcUri= Read-Host -Prompt "Please enter the URI including the .vhd file name of the source image"
$adminName= Read-Host -Prompt "Please enter a new administrator username for the VM"
$staticIPAddress= Read-Host -Prompt "Please enter a static IP address for the WAF"


#Read the JSON Parameter file
$json= Get-Content -Raw -Path $TemplateParametersFile | ConvertFrom-Json
$json.parameters.newStorageAccountName.value = $ResourceGroupName
$json.parameters.location.value = $ResourceGroupLocation
$json.parameters.dnsNameForPublicIP.value = $ResourceGroupName
$json.parameters.adminUsername.value = $adminName
$json.parameters.staticIPAddress.value= $staticIPAddress
$json | ConvertTo-Json | Set-Content -Path $TemplateParametersFile

###Create a new Resource Group for Deployment
New-AzureResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation

####Create a new destination storage account
#New-AzureStorageAccount -ResourceGroupName $ResourceGroupName -Name $json.parameters.newStorageAccountName.value -Type Standard_LRS -Location $ResourceGroupLocation

#### Get new destination storage account key
#$destStorageKey= Get-AzureStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $json.parameters.newStorageAccountName.value

#### Create the source storage account context ### 
#$srcContext = New-AzureStorageContext  –StorageAccountName "bigipv12606best" -StorageAccountKey "yGGWNx8bwxQRkg3mOlPwevLTCu/GcVsKg9Ya4+SipQXccAItlBrAYARzv7l5qicyQt2Eb7lLm3hkfFzSnJ6fcQ==" 

#### Create the destination storage account context ### 
#$destContext = New-AzureStorageContext  –StorageAccountName $json.parameters.newStorageAccountName.value -StorageAccountKey $destStorageKey.Key1
 
#### Create the container on the destination ### 
#New-AzureStorageContainer -Name $json.parameters.newStorageAccountName.value -Context $destContext 
 
#### Start the asynchronous copy - specify the source authentication with -SrcContext ### 
#$blob1 = Start-AzureStorageBlobCopy -srcUri $srcUri -SrcContext $srcContext -DestContainer $json.parameters.newStorageAccountName.value -DestBlob ($json.parameters.newStorageAccountName.value + '.vhd') -DestContext $destContext

#### Retrieve the current status of the copy operation ###
#$status = $blob1 | Get-AzureStorageBlobCopyState 
 
#### Loop until complete ###                                    
#While($status.Status -eq "Pending"){
#  $status = $blob1 | Get-AzureStorageBlobCopyState 
#  Start-Sleep 10
#  ### Print out status ###
#  #$status
#  $copyStatus= ($status.BytesCopied/$status.TotalBytes*100)
#  $copyStatus= [Math]::Round($copyStatus,2)
#  Write-Progress -Activity "Copy vhd" -Status "$copyStatus% Complete:" -PercentComplete $copyStatus
#}



New-AzureResourceGroup -Name $ResourceGroupName `
                       -Location $ResourceGroupLocation `
                       -TemplateFile $TemplateFile `
                       -TemplateParameterFile $TemplateParametersFile `
                        -Force -Verbose


$url= Get-AzurePublicIpAddress -ResourceGroupName $ResourceGroupName
Write-Host ("You can connect to the new WAF via https://{0}:8443/" -f $url.DnsSettings.Fqdn)
Write-Host ("Or you can ssh to the new WAF via {0} on port 8022" -f $url.DnsSettings.Fqdn)