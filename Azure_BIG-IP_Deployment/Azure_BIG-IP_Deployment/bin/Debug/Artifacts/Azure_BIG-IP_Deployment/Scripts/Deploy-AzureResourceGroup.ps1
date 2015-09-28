#Requires -Version 3.0

Param(
  [string] [Parameter(Mandatory=$true)] $ResourceGroupLocation,
  [string] $ResourceGroupName = 'Azure_BIG-IP_Deployment',
  [switch] $UploadArtifacts,
  [string] $StorageAccountName, 
  [string] $StorageContainerName = $ResourceGroupName.ToLowerInvariant() + '-stageartifacts',
  [string] $TemplateFile = '..\Templates\LinuxVirtualMachine.json',
  [string] $TemplateParametersFile = '..\Templates\LinuxVirtualMachine.param.dev.json',
  [string] $ArtifactStagingDirectory = '..\bin\Debug\Artifacts',
  [string] $AzCopyPath = '..\Tools\AzCopy.exe'
)

Set-StrictMode -Version 3
Import-Module Azure -ErrorAction SilentlyContinue

try {
    $AzureToolsUserAgentString = New-Object -TypeName System.Net.Http.Headers.ProductInfoHeaderValue -ArgumentList 'VSAzureTools', '1.4'
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.UserAgents.Add($AzureToolsUserAgentString)
} catch { }

$OptionalParameters = New-Object -TypeName Hashtable
$TemplateFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateFile)
$TemplateParametersFile = [System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile)

if ($UploadArtifacts)
{
    # Convert relative paths to absolute paths if needed
    $AzCopyPath = [System.IO.Path]::Combine($PSScriptRoot, $AzCopyPath)
    $ArtifactStagingDirectory = [System.IO.Path]::Combine($PSScriptRoot, $ArtifactStagingDirectory)

    Set-Variable ArtifactsLocationName '_artifactsLocation' -Option ReadOnly
    Set-Variable ArtifactsLocationSasTokenName '_artifactsLocationSasToken' -Option ReadOnly

    $OptionalParameters.Add($ArtifactsLocationName, $null)
    $OptionalParameters.Add($ArtifactsLocationSasTokenName, $null)

    # Parse the parameter file and update the values of artifacts location and artifacts location SAS token if they are present
    $JsonContent = Get-Content $TemplateParametersFile -Raw | ConvertFrom-Json
    $JsonParameters = $JsonContent | Get-Member -Type NoteProperty | Where-Object {$_.Name -eq "parameters"}

    if ($JsonParameters -eq $null)
    {
        $JsonParameters = $JsonContent
    }
    else
    {
        $JsonParameters = $JsonContent.parameters
    }

    $JsonParameters | Get-Member -Type NoteProperty | ForEach-Object {
        $ParameterValue = $JsonParameters | Select-Object -ExpandProperty $_.Name

        if ($_.Name -eq $ArtifactsLocationName -or $_.Name -eq $ArtifactsLocationSasTokenName)
        {
            $OptionalParameters[$_.Name] = $ParameterValue.value
        }
    }

    Switch-AzureMode AzureServiceManagement
	$StorageAccountKey = (Get-AzureStorageKey -StorageAccountName $StorageAccountName).Primary
    $StorageAccountContext = New-AzureStorageContext $StorageAccountName (Get-AzureStorageKey $StorageAccountName).Primary

    # Generate the value for artifacts location if it is not provided in the parameter file
    $ArtifactsLocation = $OptionalParameters[$ArtifactsLocationName]
    if ($ArtifactsLocation -eq $null)
    {
        $ArtifactsLocation = $StorageAccountContext.BlobEndPoint + $StorageContainerName
        $OptionalParameters[$ArtifactsLocationName] = $ArtifactsLocation
    }

    # Use AzCopy to copy files from the local storage drop path to the storage account container
    & "$AzCopyPath" """$ArtifactStagingDirectory"" $ArtifactsLocation /DestKey:$StorageAccountKey /S /Y /Z:""$env:LocalAppData\Microsoft\Azure\AzCopy\$ResourceGroupName"""

    # Generate the value for artifacts location SAS token if it is not provided in the parameter file
    $ArtifactsLocationSasToken = $OptionalParameters[$ArtifactsLocationSasTokenName]
    if ($ArtifactsLocationSasToken -eq $null)
    {
       # Create a SAS token for the storage container - this gives temporary read-only access to the container (defaults to 1 hour).
       $ArtifactsLocationSasToken = New-AzureStorageContainerSASToken -Container $StorageContainerName -Context $StorageAccountContext -Permission r
       $ArtifactsLocationSasToken = ConvertTo-SecureString $ArtifactsLocationSasToken -AsPlainText -Force
       $OptionalParameters[$ArtifactsLocationSasTokenName] = $ArtifactsLocationSasToken
    }
}

# Create or update the resource group using the specified template file and template parameters file
Switch-AzureMode AzureResourceManager

#Read the JSON Parameter file
$json= (Get-Content $TemplateParametersFile) -join "`n" | ConvertFrom-Json

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
  $status
}



New-AzureResourceGroup -Name $ResourceGroupName `
                       -Location $ResourceGroupLocation `
                       -TemplateFile $TemplateFile `
                       -TemplateParameterFile $TemplateParametersFile `
                        @OptionalParameters `
                        -Force -Verbose
