# Activate Azure Powershell module 
Import-Module Azure


# TODO - Replace the following values
# =================================================
$adTenant = "microsoft.onmicrosoft.com"
# Set well-known client ID for Azure PowerShell

$clientId = "XXXXXXXX-XXXX-4d50-937a-96e123b13015" 

# subscription guid 
$SubscriptionId = 'XXXXXXXX-XXXX-4802-a5e6-d9c5a43c72a0'

# Set redirect URI for Azure PowerShell

$redirectUri = New-Object System.Uri('https://localhost/')

# Azure on Internal subscription
$OfferDurableId = 'MS-AZR-0121p' # Azure on Internal subscription
# =================================================

# Set Resource URI to Azure Service Management API

$resourceAppIdURI = "https://management.azure.com/"
# Set Authority to Azure AD Tenant

$authority = "https://login.microsoftonline.com/$adTenant"

# Create Authentication Context tied to Azure AD Tenant

$authContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext($authority)

# Acquire token

$authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")

$ResHeaders = @{'authorization' = $authResult.CreateAuthorizationHeader()}

$ApiVersion = '2015-06-01-preview'
$Currency = 'USD'
$Locale = 'en-US'
$RegionInfo = 'US'

$ResourceCard = "https://management.azure.com/subscriptions/{5}/providers/Microsoft.Commerce/RateCard?api-version={0}&`$filter=OfferDurableId eq '{1}' and Currency eq '{2}' and Locale eq '{3}' and RegionInfo eq '{4}'" -f $ApiVersion, $OfferDurableId, $Currency, $Locale, $RegionInfo, $SubscriptionId

$File = $env:TEMP + '\resourcecard.json'
Invoke-RestMethod -Uri $ResourceCard -Headers $ResHeaders -ContentType 'application/json' -OutFile $File
$Resources = Get-Content -Raw -Path $File -Encoding UTF8 | ConvertFrom-Json

$OutputFilename = $env:TEMP + '\ratecardoutput.txt' # This is usually C:\Users\<username>\AppData\Local\Temp

# Insert the header line
$strHeaderLine = "{0}!{1}!{2}!{3}!{4}!{5}!{6}!{7}!{8}" -f "MeterId", "MeterSubCategory", "MeterRegion", "MeterRates", "MeterCategory", "MeterName", "Unit", "EffectiveDate",  "IncludedQuantity"

# Create the header in the output file 
$strHeaderLine | Out-File $OutputFilename

    # We create this loop to take care of tiered meter enteries in the table
    foreach($meterObj in $Resources.Meters)
    {

       
        # convert the darn PSCustomeObject created by ConvertFrom_Json to our dictionary object
        $meterRates = @{}
         $meterObj.MeterRates | Get-Member -MemberType Properties | SELECT -exp "Name" | % {
                $meterRates[$_] = ($meterObj.MeterRates | SELECT -exp $_)
          }

        $strLine = ""

        
        
        if ($meterRates.Count -gt 1)
        {
            $nCount = 0

            foreach($meterRatePair in $meterRates.GetEnumerator() | Sort -Property Value -Descending)
            {
                $strLine += $($meterRatePair.Name) + "," + $($meterRatePair.Value)

                if ($nCount -lt ($meterRates.Count -1))
                {
                    $strLine += ";";   
                }
                $nCount++; 
            }
        }
        else
        {
            # Our dictionary contains only one value and we extract that value

            foreach($meterRatePair in $meterRates.GetEnumerator())
            {
                $strLine = $($meterRatePair.Value)  # this line will execute only once.
            }
        }         
        

        $strOutputLine = "{0}!{1}!{2}!{3}!{4}!{5}!{6}!{7}!{8}" -f $meterObj.MeterId, $meterObj.MeterSubCategory, $meterObj.MeterRegion, $strLine, $meterObj.MeterCategory, $meterObj.MeterName,   $meterObj.Unit, $meterObj.EffectiveDate,  $meterObj.IncludedQuantity
        $strOutputLine | Out-File $OutputFilename -Append
    }



# Remove-Item -Force -Path $File
