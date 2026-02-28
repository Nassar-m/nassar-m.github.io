---
layout: post
title: "Automating Entra ID Lifecycle Management with PowerShell and Microsoft Graph API"
date: 2024-11-01
categories: [Automation]
tags: [powershell, graph-api, automation, lifecycle, entra-id]
excerpt: "End-to-end scripts for joiner-mover-leaver automation using Microsoft Graph API — covering group assignments, license management, access reviews, and audit logging for regulated environments."
---

> **Coming Soon** — This article is currently being written and will be published shortly.

## What This Article Will Cover

Manual joiner-mover-leaver processes are a consistent audit finding in regulated environments. They are slow, error-prone, and create orphaned accounts and excessive access. This article covers building a reliable, auditable automation layer using PowerShell and the Microsoft Graph API.

Planned topics include:

- Authentication to Microsoft Graph API using certificates and managed identities (not client secrets)
- Joiner automation — provisioning accounts, assigning licenses, adding to groups, triggering TAP for MFA registration
- Mover automation — updating attributes, adjusting group memberships, triggering access reviews on role change
- Leaver automation — disabling accounts, revoking sessions, removing licenses, archiving mailboxes
- Error handling and retry logic for production reliability
- Audit logging — writing automation actions to a Log Analytics workspace for compliance evidence
- Scheduling with Azure Automation or Logic Apps
- DORA mapping: how automation supports ICT asset management obligations

```powershell
# Example: Revoke all active sessions for a leaver
Connect-MgGraph -Scopes "User.ReadWrite.All"
Revoke-MgUserSignInSession -UserId "user@contoso.com"
```

---

*[← Back to Automation](/pages/automation/)*
