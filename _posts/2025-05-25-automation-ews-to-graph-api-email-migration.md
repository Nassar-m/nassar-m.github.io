---
layout: post
title: "From EWS to Microsoft Graph API: A Practical Migration Guide for Email Automation"
date: 2025-05-25
categories: [Automation]
tags: [graph-api, python, ews, exchange-online, oauth, automation, migration]
excerpt: "EWS is going away. This is a practical guide to migrating email automation from Exchange Web Services to Microsoft Graph API — covering the new auth model, Azure app registration, and a standalone Python script to verify the setup before touching your application code."
---

We had a recurring situation at work. A development team had an on-premises application that was sending emails on behalf of shared mailboxes using **Exchange Web Services (EWS)**. The app had been running fine for years — until the organisation moved to Exchange Online and Microsoft's deprecation timeline for EWS started becoming real.

The developers wanted to migrate their email functionality to the **Microsoft Graph API**, but they weren't familiar with the new authentication model, the Azure app registration process, or how the Graph API call structure differed from EWS. And I didn't want to debug their entire application codebase just to verify whether the Graph API side was working.

So I wrote a standalone Python script they could use to **test Graph API email sending independently** — confirm that the Azure app registration was correct, the permissions were in place, and mail was actually arriving before touching a single line of their application code.

That script and the setup steps behind it are what this post covers.

**[View script on GitHub](https://github.com/Nassar-m/GraphAPI/blob/main/send_report.py)** &nbsp;·&nbsp; **[Download raw](https://raw.githubusercontent.com/Nassar-m/GraphAPI/main/send_report.py)**

---

## Why EWS Is Going Away

EWS was the right tool for Exchange on-premises. But as organisations migrate to Exchange Online, Microsoft has been progressively restricting legacy protocols. Basic Authentication for Exchange Online was fully disabled in 2023. EWS itself, while still functional, is no longer receiving feature investment and is increasingly flagged in Microsoft Secure Score assessments.

More practically: EWS relies on either Basic Auth or delegated authentication tied to a specific user account. In modern M365 environments, that means a service account with a password that needs managing, MFA exemptions that Security teams don't like, and an auth method that doesn't appear cleanly in Entra ID sign-in logs.

The Graph API solves all of this. It uses OAuth 2.0 application permissions — the application authenticates as itself, not as a user, no service account required, and every call is fully auditable in Entra ID.

---

## The New Authentication Model

This is usually the biggest conceptual shift for developers coming from EWS.

In EWS, you authenticated with a mailbox credential — a username and password belonging to the mailbox (or an account with impersonation rights). The mailbox *was* the identity.

In Graph API with application permissions, the **Azure AD app registration is the identity**. The app authenticates against Microsoft Identity Platform using its own client ID and secret, receives an OAuth 2.0 token, and then makes API calls on behalf of any mailbox it has been granted permission to access. The token is scoped — you grant only the permissions the app actually needs, and nothing more.

```
Old model (EWS):
  App → Basic Auth (username + password) → Exchange → Mailbox

New model (Graph API):
  App → OAuth 2.0 (client ID + secret) → Entra ID → Access Token
  App → Bearer Token → Graph API → Mailbox
```

For email sending specifically, the permission you need is `Mail.Send` — an application-level permission that allows the app to send email as any mailbox in the tenant. It requires admin consent, which is appropriate given its scope.

---

## Setting Up the Azure App Registration

Before any code runs, the app registration needs to exist in your tenant. This is a one-time setup, typically done by a Global Admin or an Application Administrator.

**1. Register the application**

In the [Azure portal](https://portal.azure.com), go to **Azure Active Directory → App registrations → New registration**. Give it a meaningful name (e.g. `GraphMailSender-Prod`), leave the redirect URI blank for a daemon application, and click Register.

Note the **Application (client) ID** and **Directory (tenant) ID** from the overview page — you will need both.

**2. Create a client secret**

Go to **Certificates & secrets → New client secret**. Set a sensible expiry (12 or 24 months), click Add, and **copy the secret value immediately** — it is only shown once.

**3. Grant the Mail.Send permission**

Go to **API permissions → Add a permission → Microsoft Graph → Application permissions**. Search for `Mail.Send`, select it, and click Add permissions. Then click **Grant admin consent** — without this step the permission exists on paper but the token will be denied when used.

**4. Verify**

Your API permissions tab should show `Mail.Send` with status **Granted for [your tenant]**. If it shows "Not granted", the admin consent step was missed.

---

## The Demo Script

The script is a self-contained tool for testing Graph API email sending. The intent is straightforward: before you modify your application, use this to confirm that the Azure side is configured correctly and that mail actually lands in the target mailbox.

It uses `msal` for authentication and `requests` for the API call — both standard, widely used libraries with no Graph SDK dependency to version-pin against.

**Install dependencies:**

```bash
pip install msal requests
```

**Set your credentials as environment variables** — never put secrets in source files:

```bash
# Linux / macOS
export GRAPH_CLIENT_ID="your-client-id"
export GRAPH_CLIENT_SECRET="your-client-secret"
export GRAPH_TENANT_ID="your-tenant-id"
```

```powershell
# Windows PowerShell
$env:GRAPH_CLIENT_ID     = "your-client-id"
$env:GRAPH_CLIENT_SECRET = "your-client-secret"
$env:GRAPH_TENANT_ID     = "your-tenant-id"
```

**Then edit the configuration block at the top of the script:**

```python
SENDER_EMAIL    = "sharedmailbox@yourdomain.com"   # the mailbox sending FROM
RECIPIENT_EMAIL = ["recipient@yourdomain.com"]
EMAIL_SUBJECT   = "Graph API Test"
EMAIL_BODY      = "If you received this, the Graph API connection is working."
ATTACHMENT_PATH = None                              # or a file path to test attachments
```

**Run it:**

```bash
python send_report.py
```

If everything is configured correctly you will see:

```
2026-02-28 09:00:01 [INFO] Access token acquired.
2026-02-28 09:00:02 [INFO] Email sent successfully.
```

If something is wrong, the script will tell you exactly what failed — authentication, permissions, or mailbox not found — rather than returning a generic error buried in your application stack.

---

## What the Script Actually Does

The logic maps closely to what the Graph API documentation describes, which makes it useful as a reference when you go back to update your application code.

**Authentication** uses the client credentials flow — the app presents its client ID and secret to `login.microsoftonline.com` and receives a short-lived access token. This token is then passed as a `Bearer` header on every Graph API call.

**Sending mail** is a single POST request to:

```
POST https://graph.microsoft.com/v1.0/users/{sender}/sendMail
```

The request body is a JSON object describing the message — subject, body, recipients, and optionally attachments (Base64-encoded). The Graph API returns `202 Accepted` on success, meaning the message was accepted for delivery, not necessarily that it has arrived yet.

The equivalent EWS operation would have been `CreateItem` with `MessageDisposition` set to `SendAndSaveCopy` — structurally the same intent, different protocol.

---

## Common Issues and What They Mean

These are the errors that came up most often when the development team was working through their migration:

**`Authentication failed — AADSTS700016`**
The client ID doesn't exist in the tenant. Double-check that you're using the Application (client) ID, not the Object ID, and that it belongs to the correct tenant.

**`Graph API returned 403`**
The `Mail.Send` permission exists on the app registration but admin consent has not been granted. Go back to the API permissions tab and click Grant admin consent.

**`Graph API returned 404`**
The `SENDER_EMAIL` mailbox does not exist in Exchange Online, or the UPN doesn't match what's in the tenant directory.

**`Graph API returned 400 — InvalidRecipients`**
The recipient address is malformed or the recipient doesn't exist. Worth checking with a known-good internal address first.

**Token acquired but 401 on the API call**
The token was issued for the wrong scope or the wrong tenant. Confirm `GRAPH_TENANT_ID` matches the tenant where the app registration lives and where the mailbox exists.

---

## From Demo to Production

Once the script confirms the Graph API side is working, migrating your application code comes down to replacing the EWS call with a Graph API call using the same pattern:

1. Acquire a token using MSAL client credentials flow
2. Construct the message payload as JSON
3. POST to `/v1.0/users/{sender}/sendMail` with the Bearer token

The functions in `send_report.py` (`acquire_token`, `build_payload`, `send_mail`) are written to be importable, so you can pull them directly into your application as a starting point rather than rewriting from scratch.

For production use, a few additional considerations are worth addressing:

- **Token caching** — MSAL handles this internally when you reuse the same `ConfidentialClientApplication` instance. Avoid creating a new instance on every send call.
- **Secret rotation** — client secrets expire. Store them in Azure Key Vault and retrieve them at runtime rather than baking them into config files or pipeline variables.
- **Throttling** — Graph API enforces per-mailbox and per-tenant rate limits. For high-volume sending, consider Microsoft 365 SMTP relay or bulk mail services instead.
- **Certificate credentials** — for higher-security environments, replace the client secret with a certificate. MSAL supports both, and certificates don't expire on the same timeline.

---

## Resources

- [Microsoft Graph API — Send mail](https://learn.microsoft.com/en-us/graph/api/user-sendmail)
- [MSAL for Python](https://github.com/AzureAD/microsoft-authentication-library-for-python)
- [EWS to Graph API migration guide (Microsoft)](https://learn.microsoft.com/en-us/exchange/client-developer/exchange-web-services/migrating-to-exchange-online-and-exchange-2013)
- [Mail.Send permission reference](https://learn.microsoft.com/en-us/graph/permissions-reference#mailsend)
- [GraphAPI scripts on GitHub](https://github.com/Nassar-m/GraphAPI)
