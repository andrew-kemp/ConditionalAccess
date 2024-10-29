# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Policy.ReadWrite.AuthenticationMethod"

# Define the FIDO2 authentication method configuration
$fido2Params = @{
    "@odata.type" = "#microsoft.graph.fido2AuthenticationMethodConfiguration"
    state = "enabled"
    isAttestationEnforced = $true
    keyRestrictions = @{
        isEnforced = $true
        enforcementType = "allow"
        aaGuids = @(
            "90a3ccdf-635c-4729-a248-9b709135078f",
            "de1e552d-db1d-4423-a619-566b625cdc84"
            # Add previous AAGUIDs here to keep them stored in policy
        )
    }
}

# Convert the parameters to JSON
$fido2ParamsJson = $fido2Params | ConvertTo-Json -Depth 10

# Update the FIDO2 authentication method policy
Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/beta/authenticationMethodsPolicy/authenticationMethodConfigurations/FIDO2" -Body $fido2ParamsJson -ContentType "application/json"

Write-Host "FIDO2 authentication method configuration updated and enabled successfully." -ForegroundColor Green
