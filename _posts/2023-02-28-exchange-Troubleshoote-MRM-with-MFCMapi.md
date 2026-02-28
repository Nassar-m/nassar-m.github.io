---
layout: post
title: "How to Use MFCMapi to Troubleshoot Messaging Records Management (MRM)"
date: 2023-02-28
categories: [Exchange]
tags: [exchange-online, retention, mrm, mfcmapi, troubleshooting]
excerpt: "How to use MFCMapi to inspect individual mailbox items at the MAPI level — find exactly which retention tag is applied to a specific item when PowerShell alone is not enough to diagnose an MRM issue."
---

If you're dealing with retention policy issues in Exchange Online (M365), you need to know how to use MFCMapi to troubleshoot them. In our previous article on [Troubleshooting Retention Policies in Exchange Online](/exchange/2023/02/27/exchange-retention-policies.html), we covered the basics of retention policies and why they're important. Now we'll dive deeper into MFCMapi — the tool that lets you inspect individual items at the MAPI level to find out exactly which retention tag is applied and why.

First, download MFCMapi from GitHub. Once you have it, start the program and put it in Online mode by going to **Tools** > **Options** and selecting **Use MDB_ONLINE** and **MAPI_NO_CACHE**.

<img src="/assets/media/image1.png" style="width:6.5in;height:4.78194in" alt="MFCMapi Options dialog showing MDB_ONLINE and MAPI_NO_CACHE settings" />

Next, go to **Session** > **Logon** and open the profile name of interest.

<img src="/assets/media/image2.png" style="width:6.27083in;height:4.10417in" alt="MFCMapi Session Logon dialog" />

From there, open **Root Container** > **Top of Information Store** > right-click on the Inbox > **Open Associated Contents Table**. Sort the results by Message Class and look for the item with Message Class **IPM.Configuration.MRM**. Find the property **PR_ROAMING_XMLSTREAM** — double-click it and view the Stream (Text) window. Copy the text to an XML editor (e.g. Notepad++).

<img src="/assets/media/image3.png" style="width:6.5in;height:4.48264in" alt="MFCMapi showing the Associated Contents Table with IPM.Configuration.MRM item selected" />

<img src="/assets/media/image4.png" style="width:6.5in;height:1.07639in" alt="MFCMapi PR_ROAMING_XMLSTREAM property value" />

If you suspect a specific item is the problem, examine it directly:

1. Double-click the affected folder, or right-click > **Open Content Table**
2. Locate the message by subject, sender, recipient, or received date
3. Look for these two MAPI properties:

**PR_ARCHIVE_DATE** (`0x301F0040` — DateTime)
The date the item is scheduled for archival. Stamped by Exchange when online, calculated by Outlook when cached/offline.

**PR_ARCHIVE_TAG** (`0x30180102` — GUID)
The archive policy applied to the item (implicit or explicit). To identify which retention tag this maps to, take the hex value, convert it to a GUID, and compare it against your tags:

```powershell
Get-RetentionPolicyTag | fl Name, RetentionId
```

Match the `RetentionId` against the GUID from MFCMapi to find out exactly which tag is applied to the item.

<img src="/assets/media/image5.png" style="width:6.5in;height:3.81944in" alt="MFCMapi content table showing PR_ARCHIVE_DATE and PR_ARCHIVE_TAG properties on a mailbox item" />

<img src="/assets/media/image6.png" style="width:6.5in;height:1.77014in" alt="MFCMapi property value for PR_ARCHIVE_TAG showing hex GUID" />

By following these steps you can quickly identify which retention tag is applied to a specific item and confirm whether MRM is processing it correctly. For further reference see [Retention tags and retention policies in Exchange Online](https://learn.microsoft.com/en-us/exchange/security-and-compliance/messaging-records-management/retention-tags-and-policies).
