$ExportPath = $PSScriptRoot

try {
    # Retrieve all conditional access policies from Microsoft Graph API
    $AllPolicies = Get-MgIdentityConditionalAccessPolicy -Filter "startswith(displayName,'_')"

    if ($AllPolicies.Count -eq 0) {
        Write-Host "There are no CA policies found to export." -ForegroundColor Yellow
    }
    else {
        # Iterate through each policy
        foreach ($Policy in $AllPolicies) {
            try {
                # Get the display name of the policy
                $PolicyName = $Policy.DisplayName

                # Remove included and excluded users or groups
                $Policy.Conditions.Users.IncludeUsers = @()
                $Policy.Conditions.Users.ExcludeUsers = @()
                $Policy.Conditions.Users.IncludeGroups = @()
                $Policy.Conditions.Users.ExcludeGroups = @()

                # Convert the policy object to JSON with a depth of 6
                $PolicyJSON = $Policy | ConvertTo-Json -Depth 6

                # Write the JSON to a file in the export path
                $PolicyJSON | Out-File "$ExportPath\$PolicyName.json" -Force

                # Print a success message for the policy backup
                Write-Host "Successfully backed up CA policy: $($PolicyName)" -ForegroundColor Green
            }
            catch {
                # Print an error message for the policy backup
                Write-Host "Error occurred while backing up CA policy: $($Policy.DisplayName). $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}
catch {
    # Print a generic error message
    Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
