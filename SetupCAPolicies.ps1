 # Created by Andrew Kemp 17th Oct 2024 this script is the main one to create the accounts and groups


 Connect-MgGraph -Scopes "Policy.Read.All", "Policy.ReadWrite.ConditionalAccess", "User.Read.All", "Group.ReadWrite.All" -devicecode
 function Get-RandomPassword {
     param (
         [int]$length = 16
     )
     $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
     -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
 }
 
 
 
 #$password1 = Get-RandomPassword
 #$password2 = Get-RandomPassword
 
 $domains = Get-MgDomain
 $onMicrosoftDomain = $domains | Where-Object { $_.Id -like "*.onmicrosoft.com" -and $_.ID -notlike "*.mail.onmicrosoft.com" }
 
 if ($onMicrosoftDomain) {
     $onMicrosoftDomain | ForEach-Object { Write-Output "Found .onmicrosoft.com domain: $($_.ID)" }
     $domainName = $onMicrosoftDomain.ID  # Select the first .onmicrosoft.com domain
 } else {
     Write-Output "No .onmicrosoft.com domain found."
     return
 }
 
 # Function to check if a user exists
 function Get-UserByUPN {
     param (
         [string]$upn
     )
     $user = Get-MgUser -Filter "userPrincipalName eq '$upn'"
     return $user
 }
 
 # Function to create a new user with a specified password
 function Create-NewUser {
     param (
         [string]$upnPrefix,
         [string]$password,
         [string]$domainName
     )
     $displayName = $upnPrefix -replace "\.", " "
     $names = $upnPrefix -split "\."
     $firstName = [string]$names
     $lastName = [string]$names
     $passwordProfile = @{
         Password = $password
         ForceChangePasswordNextSignIn = $true
     }
     $newUser = New-MgUser -AccountEnabled:$true -DisplayName:$displayName -MailNickname:$upnPrefix -UserPrincipalName:"$upnPrefix@$domainName" -PasswordProfile:$passwordProfile -GivenName:$firstName -Surname:$lastName
     return $newUser
 }
 
 # Function to get or create a break glass account with a specified password
 function GetOrCreateBreakGlassAccount {
     param (
         [string]$defaultUPNPrefix,
         [string]$password,
         [string]$domainName
     )
     $upnPrefix = Read-Host "Enter the UPN prefix for $defaultUPNPrefix (or press Enter to use default)"
     if ([string]::IsNullOrWhiteSpace($upnPrefix)) {
         $upnPrefix = $defaultUPNPrefix
     }
     $upn = "$upnPrefix@$domainName"
     $user = Get-UserByUPN -upn $upn
     if ($null -eq $user) {
         Write-Host "User not found. Creating new user..."
         $user = Create-NewUser -upnPrefix $upnPrefix -password $password -domainName $domainName
     }
     return $user
 }
 
 # Main script
 $password1 = Get-RandomPassword  # Replace with your actual password
 $password2 = Get-RandomPassword  # Replace with your actual password
 
 $useExistingAccounts = Read-Host "Do you want to use existing break glass accounts? (yes/no)"
 if ($useExistingAccounts -eq "yes" -or $useExistingAccounts -eq "y") {
     $upn1 = Read-Host "Enter the UPN for the first break glass account"
     $upn2 = Read-Host "Enter the UPN for the second break glass account"
     $breakGlass1 = Get-UserByUPN -upn $upn1
     $breakGlass2 = Get-UserByUPN -upn $upn2
     if ($null -eq $breakGlass1 -or $null -eq $breakGlass2) {
         Write-Host "One or both of the specified accounts do not exist. Please check the UPNs and try again."
         exit
     }
 } else {
     $breakGlass1 = GetOrCreateBreakGlassAccount -defaultUPNPrefix "Break.Glass1" -password $password1 -domainName $domainName
     $breakGlass2 = GetOrCreateBreakGlassAccount -defaultUPNPrefix "Break.Glass2" -password $password2 -domainName $domainName
 }
 $breakGlassID1 = $breakGlass1.Id
 $breakGlassID2 = $breakGlass2.Id
 Write-Host "Break Glass Account 1 UPN: $($breakGlass1.UserPrincipalName) and ID is $breakGlassID1"
 Write-Host "Break Glass Account 2 UPN: $($breakGlass2.UserPrincipalName) and ID is $breakGlassID1"
 Write-Host "$($breakGlass1.UserPrincipalName) password is $Password1"
 Write-Host "$($breakGlass2.UserPrincipalName) password is $Password2"
 
 ##############################
 
 
 function Get-GroupByName {
     param (
         [string]$groupName
     )
     $group = Get-MgGroup -Filter "displayName eq '$groupName'"
     return $group
 }
 
 # Function to create a new group
 function Create-NewGroup {
     param (
         [string]$groupName
     )
     $mailNickname = $groupName -replace " ", ""
     $newGroup = New-MgGroup -DisplayName $groupName -MailEnabled:$false -MailNickname $mailNickname -SecurityEnabled:$true
     return $newGroup
 }
 
 # Function to create a new dynamic group
 function Create-DynamicGroup {
     param (
         [string]$groupName,
         [string]$rule
     )
     $mailNickname = $groupName -replace " ", ""
     $newGroup = New-MgGroup -DisplayName $groupName -MailEnabled:$false -MailNickname $mailNickname -SecurityEnabled:$true -GroupTypes "DynamicMembership" -MembershipRule $rule -MembershipRuleProcessingState "On"
     return $newGroup
 }
 
 # Function to get or create a group with custom prompts
 function GetOrCreateGroup {
     param (
         [string]$defaultGroupName,
         [string]$promptMessage,
         [bool]$isDynamic = $false,
         [string]$dynamicRule = ""
     )
     while ($true) {
         $useExistingGroup = Read-Host $promptMessage
         if ($useExistingGroup -eq "yes" -or $useExistingGroup -eq "y") {
             $groupName = Read-Host "Enter the group display name"
             $group = Get-GroupByName -groupName $groupName
             if ($null -eq $group) {
                 Write-Host "Group not found. Please try again."
             } else {
                 return $group
             }
         } else {
             $useTemplateName = Read-Host "Do you want to use the template name $defaultGroupName? (yes/no)"
             if ($useTemplateName -eq "yes" -or $useTemplateName -eq "y") {
                 $groupName = $defaultGroupName
             } else {
                 $groupName = Read-Host "Enter the new group name"
             }
             if ($isDynamic) {
                 $group = Create-DynamicGroup -groupName $groupName -rule $dynamicRule
             } else {
                 $group = Create-NewGroup -groupName $groupName
             }
             return $group
         }
     }
 }
 
 # Main script with custom prompts
 $group1 = GetOrCreateGroup -defaultGroupName "UserGroup1" -promptMessage "Would you like to use an existing group to target at the test users? (yes/no)"
 $group2 = GetOrCreateGroup -defaultGroupName "VIPGroup" -promptMessage "Would you like to use an existing group to target at the VIP test users? (yes/no)"
 $dynamicRule = '(user.userPrincipalName -startsWith "admin_")'
 $group3 = GetOrCreateGroup -defaultGroupName "PrivGroup" -promptMessage "Would you like to use an existing group to target at the test users with Privileged Roles assigned? (yes/no)" -isDynamic $true -dynamicRule $dynamicRule
 
 
 
 Write-Host "Group 1 ID: $($group1.Id)"
 Write-Host "Group 2 ID: $($group2.Id)"
 Write-Host "Group 3 ID: $($group3.Id)" 
 
 $GrpUserID = $group1.Id
 $GrpVIPID = $group2.Id
 $GrpPrivID = $group3.Id
 
 
 # Add the Global Admin Role to the Break Glass Accounts
 
 # Function to assign a role to a user
 function Assign-RoleToUser {
     param (
         [string]$roleName,
         [string]$userID
     )
     $role = Get-MgDirectoryRole | Where-Object { $_.DisplayName -eq $roleName }
 
     if (-not $role) {
         # If the role does not exist, create it
         $roleTemplate = Get-MgDirectoryRoleTemplate | Where-Object { $_.DisplayName -eq $roleName }
         $role = New-MgDirectoryRole -DisplayName $roleName -RoleTemplateId $roleTemplate.Id
     }
 
     # Assign the role to the user
     $roleMember = @{
         "@odata.id" = "https://graph.microsoft.com/v1.0/users/$userID"
     }
 
     New-MgDirectoryRoleMemberByRef -DirectoryRoleId $role.Id -BodyParameter $roleMember
 
     Write-Output "Global Admin role assigned to user ID: $userID"
 }
 
 # Assign the Global Administrator role to both users
 $roleName = "Global Administrator"
 Assign-RoleToUser -roleName $roleName -userID $breakGlassID1
 Assign-RoleToUser -roleName $roleName -userID $breakGlassID2
 
 
 # Add the 2 Break Glass Accounts as the Group Owners
 
 # Function to add an owner to multiple groups with a check
 function Add-OwnerToGroups {
     param (
         [string]$ownerID,
         [array]$groupIDs
     )
     $ownerRef = @{
         "@odata.id" = "https://graph.microsoft.com/v1.0/users/$ownerID"
     }
     foreach ($groupID in $groupIDs) {
         # Check if the user is already an owner
         $existingOwners = Get-MgGroupOwner -GroupId $groupID
         $isAlreadyOwner = $existingOwners | Where-Object { $_.Id -eq $ownerID }
 
         if (-not $isAlreadyOwner) {
             New-MgGroupOwnerByRef -GroupId $groupID -BodyParameter $ownerRef
             Write-Output "Owner added to group ID: $groupID. The owner ID is: $ownerID"
         } else {
             Write-Output "User ID: $ownerID is already an owner of group ID: $groupID"
         }
     }
 }
 
 # Group IDs
 $groupIDs = @($GrpUserID, $GrpVIPID, $GrpPrivID)
 
 # Add owners to the groups
 Start-Sleep -Seconds 10
 Add-OwnerToGroups -ownerID $breakGlassID1 -groupIDs $groupIDs
 Add-OwnerToGroups -ownerID $breakGlassID2 -groupIDs $groupIDs
 
 ###############################
 # Create the Policies
 $currentDirectory = Get-Location
 $jsonFiles = Get-ChildItem -Path "$currentDirectory" -Filter *.json
 
 
 
 foreach ($file in $jsonFiles) {
     $jsonContent = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
 
     # Ensure the Conditions and Users properties exist
     if (-not $jsonContent.PSObject.Properties.Match("Conditions")) {
         $jsonContent | Add-Member -MemberType NoteProperty -Name "Conditions" -Value @{ Users = @{} }
     }
     if (-not $jsonContent.Conditions.PSObject.Properties.Match("Users")) {
         $jsonContent.Conditions | Add-Member -MemberType NoteProperty -Name "Users" -Value @{}
     }
     if (-not $jsonContent.Conditions.Users.PSObject.Properties.Match("ExcludeUsers")) {
         $jsonContent.Conditions.Users | Add-Member -MemberType NoteProperty -Name "ExcludeUsers" -Value @()
     }
     if (-not $jsonContent.Conditions.Users.PSObject.Properties.Match("IncludeGroups")) {
         $jsonContent.Conditions.Users | Add-Member -MemberType NoteProperty -Name "IncludeGroups" -Value @()
     }
 
     # Determine the group to include based on the policy name
     $policyName = $jsonContent.DisplayName
     if ($policyName -like "9*") {
             $includeGroupIds = $GrpPrivID # Add the Privileged Group to the included user group
         } elseif ($policyName -like "2*") {
             $jsonContent.Conditions.Users.IncludeGroups = @($GrpVIPID) # Add the VIP Users to the included users
         } elseif ($policyName -like "3*") {
             $jsonContent.Conditions.Users.IncludeGroups = @($GrpVIPID, $GrpUserID)  # Combine both groups
         } else {
             
            $jsonContent.Conditions.Users.IncludeGroups = @($GrpUserID) # Add the USers Group to the included users
         }
 
     # Update the JSON content to exclude the user IDs and include the appropriate group ID
     $jsonContent.Conditions.Users.ExcludeUsers = @($BreakGlassID1,$BreakGlassID2)
  
 
     # Remove the 'id' field if it exists
     if ($jsonContent.PSObject.Properties.Match("id")) {
         $jsonContent.PSObject.Properties.Remove("id")
     }
 
     # Convert the updated JSON content back to JSON format
     $updatedJsonContent = $jsonContent | ConvertTo-Json -Depth 10
 
     # Create the conditional access policy
     New-MgIdentityConditionalAccessPolicy -BodyParameter $updatedJsonContent
 }
  
 