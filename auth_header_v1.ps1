#region Construct Azure Datamarket access_token 
#Refer obtaining AccessToken (http://msdn.microsoft.com/en-us/library/hh454950.aspx) 

$username      = 'service@tstanley.onmicrosoft.com'
$password      = 'FruitL00p!'
$ClientID      = '5937c9a9-ddeb-4a08-968d-ba54a4526ee7'
$client_Secret = ‘Lk6fT1MclEEkeLknSKmAPew9h774ubZTbPm+8zXb+wE='
$loginURL      = "https://login.windows.net"
$tenantdomain  = "tstanley.onmicrosoft.com"

# If ClientId or Client_Secret has special characters, UrlEncode before sending request
#$clientIDEncoded = [System.Web.HttpUtility]::UrlEncode($ClientID)
#$client_SecretEncoded = [System.Web.HttpUtility]::UrlEncode($client_Secret)

# Login to Azure
Add-AzureAccount
Switch-AzureMode AzureResourceManager

#Define the body of the request
#$Body = "grant_type=client_credentials&client_id=$clientIDEncoded&client_secret=$client_SecretEncoded&scope=http://api.microsofttranslator.com"
$body          = @{grant_type="client_credentials";resource_id=$resource;client_id=$ClientID;client_secret=$Client_Secret}
$oauth         = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body

# Create the headers
$headerParams  = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}

## How to use the header to make a call
## $allProviders = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/${subscriptionId}/providers?api-version=2014-04-01-preview" -Headers $authHeader -Method Get -Verbose).Value
#endregion

$tenantId = '37815a62-f240-4ff0-999c-8dd0774befe9'
$clientId = '5937c9a9-ddeb-4a08-968d-ba54a4526ee7'
$client_Secret = ‘Lk6fT1MclEEkeLknSKmAPew9h774ubZTbPm+8zXb+wE='
$subscriptionId = 'c0e489f9-cf57-4472-a3ed-f6bc7cd70043'
$authUrl = "https://login.windows.net/${tenantId}"
$AuthContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]$authUrl
$credential =  New-Object -TypeName Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential -ArgumentList ($ClientID, $client_Secret)
$result = $AuthContext.AcquireToken("https://management.core.windows.net/",$credential)
 
$authHeader = @{
'Content-Type'='application\json'
'Authorization'=$token.CreateAuthorizationHeader()
}

$allProviders = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/${subscriptionId}/providers?api-version=2014-04-01-preview" -Headers $authHeader -Method Get -Verbose).Value