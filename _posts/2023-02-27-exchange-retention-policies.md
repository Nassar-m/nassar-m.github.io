---
layout: post
title: "Exchange Online Retention Policies: A Practical Configuration Guide for Regulated Environments"
date: 2023-02-27
categories: [Exchange]
tags: [exchange-online, retention, compliance, purview, bafin, dora]
excerpt: "Step-by-step troubleshooting for Exchange Online retention issues — diagnosing legacy MRM policy failures, clearing full Recoverable Items folders blocked by compliance policies, and recovering bulk-deleted items using PowerShell."
---

You're an Exchange administrator and you discover that an important mailbox has stopped receiving emails due to quota issues. You assigned a retention policy weeks ago to reduce the quota — but the quota hasn't moved. In this article we'll walk through troubleshooting both legacy MRM retention policies and compliance retention policies, and how to use MFCMapi to inspect individual item tags.

**NOTE:** MRM will not process a mailbox if the size is less than 10 MB or if there is no retention policy assigned.

---

## Part 1: Troubleshooting Legacy Retention Policy (MRM)

We'll work through these steps in order. You may not need all of them — often the first two or three will point you to the fix. But it's worth understanding the full sequence before you start.

1. Identify the assigned retention policy
2. Check the retention tag actions
3. Enforce MFA to process the mailbox
4. Verify MFA processed correctly
5. Review mailbox diagnostics for MRM
6. Examine mailbox folder statistics

---

### 1. Identify the assigned retention policy

Two kinds of retention policy can affect a mailbox: the Exchange (MRM) Retention Policy and the Compliance Retention Policy. Start by running the command below to see which is assigned, and whether Retention Hold or ELC processing is enabled or disabled.

```powershell
Get-Mailbox <Identity> | fl InPlaceHolds, Retention*, ELC*
```

![MRM policy check output showing InPlaceHolds, RetentionHoldEnabled and ELCProcessingDisabled](https://user-images.githubusercontent.com/113264461/207298507-4a47e96b-de13-4959-b9ec-e8960b600fb2.png)

Check these three parameters:

- **RetentionPolicy** — confirms which policy is assigned (e.g. "Default MRM Policy")
- **ELCProcessingDisabled** — must be `False`. When `True`, the Managed Folder Assistant (MFA) is blocked from processing the mailbox entirely.
- **RetentionHoldEnabled** — must be `False`. When `True`, MFA processes tags but won't expire visible items. Items in the Recoverable Items folder are still processed.

---

### 2. Check the retention tag actions

Find out which tags are in the assigned policy and what their actions are:

```powershell
Get-RetentionPolicy -Identity "Default MRM Policy" | select -ExpandProperty RetentionPolicyTagLinks

$tags = Get-RetentionPolicy -Identity "Default MRM Policy" | select -ExpandProperty RetentionPolicyTagLinks
$tags | foreach { Get-RetentionPolicyTag $_ | ft Name, Type, Age*, Retention* }
```

![Output showing retention tag names, types, AgeLimitForRetention and RetentionAction](https://user-images.githubusercontent.com/113264461/207298802-8ed9ce54-71e3-47ea-b8e5-95c1e2287e79.png)

Confirm that the correct tags are applied and note what the Default Retention Tag (DRT) is doing.

---

### 3. Enforce MFA to process the mailbox

Once you've confirmed the policy and tags are correct, force MFA to begin processing:

```powershell
Start-ManagedFolderAssistant -Identity <User>
```

**NOTE:** SLA for MFA processing in Exchange Online is up to 7 days.

If you recently changed the retention policy, use `-FullCrawl` to recalculate the entire mailbox:

```powershell
Start-ManagedFolderAssistant -Identity <User> -FullCrawl
```

---

### 4. Verify MFA processed correctly

Running MFA won't tell you if it succeeded. After some time, check the last successful processing timestamp:

```powershell
$MRMLogs = [xml] ((Export-MailboxDiagnosticLogs <User> -ExtendedProperties).MailboxLog)
$MRMLogs.Properties.MailboxTable.Property | Where-Object { $_.Name -like "*ELC*" }
```

![Mailbox diagnostics output showing ELCLastSuccessTimestamp and item counts](https://user-images.githubusercontent.com/113264461/207299206-b411ec8a-a07b-495c-a9ff-30a784b7ca85.png)

This shows the timestamp of the last successful run and how many items were deleted or archived.

---

### 5. Review mailbox diagnostics for MRM

If the quota still isn't reducing, check for MRM exceptions on the primary mailbox:

```powershell
Export-MailboxDiagnosticLogs <Identity> -ComponentName MRM
```

![MRM diagnostic log output showing any processing exceptions](https://user-images.githubusercontent.com/113264461/207299337-c12fb3e0-4952-4659-979e-67ad8a8ba517.png)

Common errors:

- `Resource 'DiskLatency(GUID:...) is unhealthy and should not be accessed`
- `Resource 'Processor' is unhealthy and should not be accessed`

If the error has been present for less than two days, re-run MFA. If it persists beyond two days, contact Microsoft Support and proceed to Part 2.

---

### 6. Examine mailbox folder statistics

If you still suspect MRM isn't processing the full mailbox, check folder statistics:

```powershell
Get-MailboxFolderStatistics <User> -FolderScope Inbox -IncludeOldestAndNewestItems -IncludeAnalysis | select Name, Items*, Oldest*, Top*
```

![Mailbox folder statistics output showing item counts and sizes per folder](https://user-images.githubusercontent.com/113264461/207299418-90d1ef0d-b3d2-4132-8e66-163e46c68113.png)

Two things that will stop MRM from processing a folder:

- **Items larger than 150 MB** — cannot be moved to archive automatically; must be moved or deleted manually
- **Folders exceeding 1 million items** — MRM stops processing that folder entirely; you must manually reduce the item count

---

## Part 2: Troubleshooting Compliance Retention Policy

Part 1 covered legacy MRM. This part covers compliance retention policies — the ones managed through Microsoft Purview.

---

### Scenario 1: Unable to clear the Recoverable Items folder

A mailbox stops receiving meeting requests with error `554 5.2.0 STOREDRV.Deliver.Exception:QuotaExceededException`. The Recoverable Items folder is full and a compliance retention policy is preventing MFA from purging items.

**Step 1 — Identify the compliance retention policy**

Use the Policy Lookup tab in the Compliance admin centre, or run:

```powershell
Get-Mailbox <Identity> | fl InPlaceHolds
```

![Output showing InPlaceHolds with a compliance retention policy GUID](https://user-images.githubusercontent.com/113264461/207303057-7d9538a5-dacc-4fed-900b-eb6473e3ca2d.png)

**Step 2 — Verify what the retention rule does**

Using the policy GUID from the previous command, retrieve the rule, its action, and its retention duration:

```powershell
Get-Mailbox <Identity> | fl InPlaceHolds
Get-RetentionComplianceRule | Where-Object { $_.Policy -match "<PolicyGUID>" } | fl Name, Retention*
```

![Compliance retention rule output showing RetentionAction and RetentionDuration](https://user-images.githubusercontent.com/113264461/207303166-7f209679-f4ff-4305-a34a-e9dc419c7ed3.png)

**Step 3 — Exclude the mailbox from the policy (if needed)**

If the compliance policy is the root cause, exclude the affected mailbox. In the Compliance admin centre, locate the policy under **Information governance > Retention policies**, click through to the Locations tab, and add the mailbox as an exclusion.

![Compliance admin centre showing the exclusion option on the Locations tab](https://user-images.githubusercontent.com/113264461/207303261-e7bc5672-2f6e-4454-9520-7e72926178ae.png)

Or via PowerShell:

```powershell
Set-RetentionCompliancePolicy -Identity "<PolicyName>" -AddExchangeLocationException "<Mailbox>"
```

Allow up to 24 hours for the exclusion to distribute. Verify distribution with:

```powershell
Get-RetentionCompliancePolicy "<PolicyName>" -DistributionDetail | fl *Distribution*, *ExchangeLocation*
```

If distribution shows an error:

```powershell
Set-RetentionCompliancePolicy -Identity "<PolicyName>" -RetryDistribution
```

**Step 4 — Remove the delay hold**

After any hold is removed, a 30-day delay hold is automatically applied. Check and remove it:

```powershell
Set-Mailbox <Username> -RemoveDelayHoldApplied
```

---

### Scenario 2: Restoring bulk-deleted items

If a compliance policy that deletes content was accidentally applied to the wrong mailboxes, follow these steps to recover the items.

First, disable ELC processing to pause MFA while you restore:

```powershell
Set-OrganizationConfig -ELCProcessingDisabled $True
```

Then restore deleted items from the Recoverable Items folder, filtered by deletion date:

```powershell
Get-RecoverableItems -Identity <User> -ResultSize Unlimited -FilterItemType IPM.Note -FilterStartTime "dd/mm/yyyy" | Restore-RecoverableItems
```

Re-enable ELC processing once the restore is complete:

```powershell
Set-OrganizationConfig -ELCProcessingDisabled $False
```

**References:**
- [Recover deleted messages in Exchange Online](https://learn.microsoft.com/en-us/exchange/recipients-in-exchange-online/manage-user-mailboxes/recover-deleted-messages)
- [Get-RecoverableItems](https://learn.microsoft.com/en-us/powershell/module/exchange/get-recoverableitems)
- [Restore-RecoverableItems](https://learn.microsoft.com/en-us/powershell/module/exchange/restore-recoverableitems)
