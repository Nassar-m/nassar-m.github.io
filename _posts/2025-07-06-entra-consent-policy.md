---
layout: post
title: "Entra ID Application Consent Policies: Controlling OAuth Permissions at Enterprise Scale"
date: 2025-01-01
categories: identity-access
tags: [entra-id, consent, oauth, app-governance, security]
excerpt: "How to design and enforce application consent policies in Entra ID to prevent over-permissioned OAuth apps — covering admin consent workflows, permission classification, and app governance in enterprise environments."
---
# Custom app consent policies in Microsoft Entra ID

*July 6, 2025*

Someone in your org clicks "Accept" on an OAuth prompt. The app now has `Mail.Send` access for their account — and nobody got an alert.

That's the default behavior in most Entra tenants. Any user can consent to any app requesting low-privilege permissions, and it happens silently. Consent phishing attacks rely on exactly this: trick a user into approving a legitimate-looking OAuth app, get persistent access without ever touching a password.

The fix isn't disabling user consent entirely — that just creates a helpdesk bottleneck. The better option is scoped consent policies: you define exactly which users can approve consent, for which app, for which permissions. Everyone else gets blocked.

This guide walks through that setup end-to-end using PowerShell and Microsoft Graph. One heads-up: the steps aren't in the most intuitive order — you create the policy first, then scope it, then build the role, then assign it. Just follow the sequence and it'll make sense by the end.

## Prerequisites

You'll need one of these roles:

- Privileged Role Administrator
- A custom directory role with app consent policy management permissions

And these Microsoft Graph permissions:

- `Policy.ReadWrite.PermissionGrant`
- `RoleManagement.ReadWrite.Directory`
- `Group.ReadWrite.All`
- `Application.Read.All`

Install and connect the Graph PowerShell module before starting:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser

Connect-MgGraph -Scopes "Policy.ReadWrite.PermissionGrant", "RoleManagement.ReadWrite.Directory", "Group.ReadWrite.All", "Application.Read.All"
```

---

## Step 1: Collect the object IDs you need

Microsoft Graph works with object IDs, not display names. Before creating anything, gather the IDs for the app, the Graph API service principal, and the specific permissions you want to allow.

```powershell
# Get the Contoso app service principal
$ContosoApp = Get-MgServicePrincipal -Filter "displayName eq 'Contoso'"

# Get the Microsoft Graph service principal
$GraphApp = Get-MgServicePrincipal -Filter "servicePrincipalNames/any(n:n eq 'https://graph.microsoft.com/')"

# Pull the specific permission IDs
$MailSendPermission = $GraphApp.Oauth2PermissionScopes | Where-Object {$_.Value -eq "Mail.Send"}
$UserReadPermission = $GraphApp.Oauth2PermissionScopes | Where-Object {$_.Value -eq "User.Read"}
```

## Step 2: Create the consent policy

This creates an empty policy object. The scope gets defined in the next step.

```powershell
New-MgPolicyPermissionGrantPolicy `
    -Id "Contoso-restricted-policy" `
    -DisplayName "Contoso Application Restricted Access Policy" `
    -Description "Restricts Contoso app consent to Mail.Send and User.Read for specific user groups"
```

## Step 3: Define what the policy allows

This is where you attach the actual restrictions — which app, which API, which permissions.

```powershell
New-MgPolicyPermissionGrantPolicyInclude `
    -PermissionGrantPolicyId "Contoso-restricted-policy" `
    -PermissionType "delegated" `
    -ResourceApplication $GraphApp.AppId `
    -Permissions @($MailSendPermission.Id, $UserReadPermission.Id) `
    -ClientApplicationIds @($ContosoApp.AppId)
```

You can also use exclude conditions instead — useful if you want to allow everything *except* certain apps or permissions. The full list of supported parameters is in the [Microsoft Learn docs](https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/manage-app-consent-policies).

## Step 4: Create a custom role with consent permissions

To allow users to grant consent under this policy, they need a directory role with this specific permission:

```
microsoft.directory/servicePrincipals/managePermissionGrantsForSelf.{policyId}
```

Replace `{policyId}` with your policy ID from Step 2 — in this case, `Contoso-restricted-policy`.

```powershell
$params = @{
    description = "Allows users to consent to the Contoso app with restricted permissions"
    displayName = "Contoso Application Consent Manager"
    rolePermissions = @(
        @{
            allowedResourceActions = @(
                "microsoft.directory/servicePrincipals/managePermissionGrantsForSelf.Contoso-restricted-policy"
            )
        }
    )
    isEnabled = $true
}

New-MgRoleManagementDirectoryRoleDefinition -BodyParameter $params
```

## Step 5: Assign the role

Assign it to the group of users who should be able to approve consent for this app:

```powershell
$ContosoGroup = Get-MgGroup -Filter "displayName eq 'Contoso Application Users'"

New-MgRoleManagementDirectoryRoleAssignment `
    -RoleDefinitionId $CustomRole.Id `
    -PrincipalId $ContosoGroup.Id `
    -DirectoryScopeId "/"
```

You can also verify the assignment in the Entra admin center under **Identity > Roles and administrators**.

## Step 6: Validate the setup

Check the policy:

```powershell
Get-MgPolicyPermissionGrantPolicy -PermissionGrantPolicyId "Contoso-restricted-policy" | fl
```

Check the include conditions:

```powershell
Get-MgPolicyPermissionGrantPolicyInclude -PermissionGrantPolicyId "Contoso-restricted-policy" | fl
```

Verify the role and its permissions:

```powershell
Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Contoso Application Consent Manager'" | fl

Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Contoso Application Consent Manager'" | Select -ExpandProperty RolePermissions | fl
```

## Troubleshooting

If consent fails or users can't grant permissions, start here:

- **Sign-in logs** in the Entra admin center will usually show you the specific error code and which app/user triggered it.
- Confirm the Contoso service principal exists and its app ID matches what's in the policy.
- Make sure the custom role is enabled and assigned to the right group.
- Double-check that the affected users are actually members of that group.

For audit reports and admin consent request monitoring, this article from Office 365 IT Pros is worth a read: https://office365itpros.com/2023/12/22/admin-consent-requests/

---

## Wrapping up

This took several steps, but you now have a policy that limits who can grant permissions, which app they can consent to, and which specific permissions are in scope. That's a meaningful reduction in your attack surface compared to tenant-wide consent settings — and it doesn't require blocking consent entirely.

The PowerShell setup is a bit tedious the first time. Once you have the pattern down, replicating it for other apps is mostly copy-paste with different IDs.
