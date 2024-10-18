# Get the current admin consent request policy
$adminConsentPolicy = Get-MgPolicyAdminConsentRequestPolicy

# Update the policy to disable user consent and allow only admins to consent to apps
$adminConsentPolicy.UserConsentSettings = @{
    IsEnabled = $false
    Permissions = @()
}

# Apply the updated policy
Update-MgPolicyAdminConsentRequestPolicy -AdminConsentRequestPolicy $adminConsentPolicy

Write-Host "User consent to applications has been turned off. Only admins can consent to third-party apps." -ForegroundColor Green
