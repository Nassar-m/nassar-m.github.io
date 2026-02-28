---
layout: post
title: "Exchange Online Retention Policies: A Practical Configuration Guide for Regulated Environments"
date: 2023-02-27
categories: exchange
tags: [exchange-online, retention, compliance, purview, bafin, dora]
excerpt: "A hands-on guide to designing and implementing retention policies in Exchange Online using Microsoft Purview — covering regulatory retention requirements, litigation hold, and common configuration mistakes in regulated environments."
---

step-by-step guide to help you troubleshoot Legacy Retention policy like a pro!  


Image You're an Exchange administrator, and you discover that one essential mailbox has stopped operating and is unable to send or receive emails due to quota issues, despite the fact that you have assigned a restricted retention policy to the mailbox to reduce the high quota, but it seems the quota is not reduced after a week and causing a bigger issue.
In this article, we will demonstrate troubleshooting exchange online retention policies, as well as new compliance retention policies and using MFCMapi to examine the items tags.
Part1: Troubleshooting Legacy retention policy:
It is important to know that you do not have to go through all the troubleshooting steps listed below to resolve the MRM issue; you might solve the problem with the first two or three steps, but in this blog, we will try to cover all the various troubleshooting procedures that you could need. Typically, you will use Start-ManagedFolderAssistance to start processing individual mailboxes, which can take up to 7 days on Exchange Online. However, we urge that you examine the situation from the beginning until you identify and fix the root cause. If there is no problem, it may be resolved automatically after MFA (Managed Folder Assistance) processes the mailbox.
In the first part we will discuss the points below:
1.      Identify the assigned retention policy to your mailbox
2.      Check the actions of your retention tags included in the policy
3.      Enforce MFA to process your mailbox
4.      Verify if MFA processed the mailbox correctly
5.      Review Mailbox diagnostics for MRM component
6.      Examine mailbox folder statistics

NOTE: MRM will not process a mailbox if the size of the mailbox is less than 10 MB or if there is no retention policy assigned to the mailbox.

1.    Identify the assigned exchange retention policy to your mailbox:  
 There are two kinds of retention policies that may have an impact on your inbox. The Exchange Retention Policy, which we will troubleshoot in part 1, and the Compliance Retention Policy which we will address in part 2. Therefore, it is usually a good idea to start by running the command below to see which one is assigned and if Retention hold and ELC processing enabled or disabled or your mailbox.
Get-Mailbox <Identity> | fl InPlaceHolds, Retention*, ELC*
![image](https://user-images.githubusercontent.com/113264461/207298507-4a47e96b-de13-4959-b9ec-e8960b600fb2.png)

In this example, we will check the three parameters below and see if there is any retention hold or if ELC is disabled.
Check the Retention Policy that has been applied to your mailbox. In this case, we can observe that the policy that has been assigned is "Default MRM Policy.” For more info: Retention tags and retention policies in Exchange Online | Microsoft Docs
Confirm that ELcProcessingDisabled is false (default value). When the ElcProcessingDisabled property is set to True, it prevents the Managed Folder Assistant from processing the mailbox at all. So, in addition to not processing the MRM retention policy, other functions performed by the Managed Folder assistant, such as expiring items in the Recoverable Items folder by marking them for permanent removal, will not be performed. Except the processing of deleted items.
Verify the Retention hold is not enabled (“false”). If RetentionHoldEnabled is true then MFA will continue to process the MRM retention policy on the mailbox (including applying retention tags to items), but it will not expire items in folders that are visible to the user (that is, in folders in the IPM subtree of the mailbox). However, the Managed Folder Assistant will continue to process items in the Recoverable Items folder, including purging expired items. So, setting ElcProcessingDisabled to True is more restrictive and has more consequences than setting the RetentionHoldEnabled property to True. For more information: Place a mailbox on retention hold in Exchange Online | Microsoft Docs

2.    Check the retention tags actions included in the policy
After reviewing the retention policy, we need to know which Retention tags have been assigned to the mailbox and what their actions are. To find out, we must execute the following commands:

Get-RetentionPolicy -Identity “Default MRM Policy” | select -ExpandProperty retentionpolicytaglinks
$tags = Get-RetentionPolicy -Identity “Default MRM Policy” | select -ExpandProperty retentionpolicytaglinks
$tags | foreach {Get-RetentionPolicyTag $_ | ft Name, Type, Age*, Retention*}

![image](https://user-images.githubusercontent.com/113264461/207298802-8ed9ce54-71e3-47ea-b8e5-95c1e2287e79.png)

In the output above, you can see further information about each tag in the retention policy applied to your mailbox:
The type of Tags included in your policy.
The action (Retention Action) applied to items
As well as at which age (AgeLimitForRetention), etc.
You need to determine whether these tags are the applicable tags to your mailbox and what the default tag DRT (Default Retention Tag) applied to your mailbox is.

3.    Enforce MFA to process the mailbox
Use the following command to force MFA (Managed Folder Assistant) to begin processing the impacted mailbox after checking the policies and tags and confirming that the correct tags are applied:
Start-ManagedFolderAssistant -Identity <User>
NOTE: the SLA to process the mailbox in Exchange Online is up to 7 days.
If you changed the mailbox's retention policy, you might use the -FullCrawl argument to recalculate the whole mailbox:
 Start-ManagedFolderAssistant -Identity <User> -FullCrawl
This parameter is available only in the cloud-based service. The FullCrawl switch recalculates the application of tags across the whole mailbox. You do not need to specify a value with this switch.

4.    Verify MFA processing
Verify that MFA properly processed the mailbox. Running the MFA with or without a full crawl will not inform you whether MRM processed the mailbox correctly or not. After some time, you may view the most recent MFA processing timestamp (ELCLastSuccessTimestamp).
 $MRMLogs = [xml] ((Export-MailboxDiagnosticLogs <user> -ExtendedProperties).mailboxlog)
$MRMLogs.Properties.MailboxTable.Property | ? {$_.Name -like “*ELC*”}

![image](https://user-images.githubusercontent.com/113264461/207299206-b411ec8a-a07b-495c-a9ff-30a784b7ca85.png)

The mailbox diagnostics will display the number of deleted or archived items that MRM processed last time as well as the time stamp of last successful run.

5.    Check MRM mailbox diagnostics
If, after double-checking the policy, tags, and latest processing time, you still believe this was ineffective and the mailbox quota is not being reduced as expected because MFA did not process the mailbox correctly, you may verify MRM exceptions (if any) from the primary mailbox – use:
Export-MailboxDiagnosticLogs <identity> -ComponentName MRM

![image](https://user-images.githubusercontent.com/113264461/207299337-c12fb3e0-4952-4659-979e-67ad8a8ba517.png)


Example of the error:
Resource 'DiskLatency(GUID:... Name:??? Volume:\...) is unhealthy and should not be accessed.
or Resource 'Processor' is unhealthy and should not be accessed
Determine the frequency with which the same error has happened. If the problem has not been present for more than two days, re-run MFA. If the issue persists or has been present for more than two days, you should contact Microsoft support. but in the meanwhile, please review the compliance retention policy (Part 2).

6.    Examine mailbox folder statistics

If the mailbox quota is still not reduced and you see some errors in the diagnostics and you still suspect MRM did not process the entire mailbox properly, double-check mailbox folder statistics. In certain circumstances, this may direct you to the root cause of the problem:  
 Get-MailboxFolderStatistics <User> -FolderScope inbox -IncludeOldestAndNewestItems -IncludeAnalysis | select name, items*, oldes*, top*

![image](https://user-images.githubusercontent.com/113264461/207299418-90d1ef0d-b3d2-4132-8e66-163e46c68113.png)

o   NOTE: If you have an Item that is larger than 150 MB, there will be a problem moving it to the archive, and you will have to move it manually or remove it.
o   Consider that the maximum number of objects per folder is one million. If any of the folders reaches the 1 million item limit, nothing will be transferred to that folder. This is common for the Inbox folder, and ELC Assistant simply produces an error.
For example, a big item, like in the previous example, may cause the mailbox to stop processing, in which case you must manually move the item to the archive or delete it. Similarly, to the 1M restriction, you must manually reduce the number of items in the folder to allow MRM to handle the mailbox again.

Part2: Troubleshooting compliance retention policy:

Part one discussed how to troubleshoot the legacy retention policy in Exchange online, and this second part will look at the compliance retention policy, going over two different scenarios. Please refer to this article if you need to continue troubleshooting the compliance retention rules.
Scenario 1: Unable to clear the recoverable items folder
One of my customers complained than an important mailbox was unable to receive meeting requests and that the sender was receiving this error message ”'554 5.2.0 STOREDRV.Deliver.Exception:QuotaExceededException.MapiExceptionShutoffQuotaExceeded; Failed to process message due to a permanent exception with message.”  We later discovered that this mailbox had a full recoverable items folder. Together we will go through the steps needed to solve this issue:

1. Identify the compliance retention policy applied to your mailbox:
We will also start by identifying the associated policy to the impacted mailbox by using the policy lookup tab under compliance admin center: Information governance - Microsoft 365 compliance

![image](https://user-images.githubusercontent.com/113264461/207302937-1c2cd8c8-3e52-42c2-921b-58a55ace37a2.png)

Or you can do it using the PowerShell command below:
Get-Mailbox <Identity> | fl InPlaceHolds

![image](https://user-images.githubusercontent.com/113264461/207303057-7d9538a5-dacc-4fed-900b-eb6473e3ca2d.png)

Examine the Compliance retention policy which will be found under InPlaceHolds parameter. For more info: Learn about retention policies & labels to automatically retain or delete content – Microsoft 365 Compliance | Microsoft Docs

2. Verify compliance retention rule applied to your mailbox, and what it does
This only applies if a compliance Retention policy has been assigned under the "InPlaceHolds" Parameter.
To identify the compliance retention rule, run the following command to obtain the rule, the retention actions, and the duration for this rule. Using the policy GUID acquired from the previous command (Get-Mailbox | fl InPlaceHold), you may retrieve the compliance rule, action on this policy that is applied to your mailbox:
Get-Mailbox | fl InPlaceHolds
Get-RetentionComplianceRule | ? {$_.Policy -match “18aec5b1-04d8-40e4-8290-7b35f9834f24”}| fl Name, Retention*

![image](https://user-images.githubusercontent.com/113264461/207303166-7f209679-f4ff-4305-a34a-e9dc419c7ed3.png)

In the above example, the items will be kept for five years (1825 days) before being deleted. or you can review the policy from compliance Admin center under Information governance - Microsoft 365 compliance
You have two possibilities at this moment. Archive the items in the recoverable items folder using a legacy retention policy, which is the best choice for keeping the data while being compliant with your company policy, or permanently delete the data after consulting with your compliance team. In this case, my customer decided to permanently delete the recoverable items, knowing that the data would be forever erased and unrecoverable. As a result, we proceeded to the following step, which would be to exclude the impacted user from the compliance retention policy.

If needed, exclude the impacted mailbox from the compliance retention policy:
If you found that the compliance policy is the primary cause of the high quota by retaining the items for a specific period and preventing MFA from purging the items, such as in this case where the compliance policy retaining the items for 5 years, the items will not be purged before this period. Simply follow the steps below to exclude your mailbox from that policy:
Locate the compliance policy from the previous step under the retention policy tab from compliance Admin center, modify it, and then click Next > Next until you reach the location tab, where you can choose the exclusion button to exclude your mailbox from the policy.

![image](https://user-images.githubusercontent.com/113264461/207303261-e7bc5672-2f6e-4454-9520-7e72926178ae.png)

Or use the command: Set-RetentionCompliancePolicy -Identity <policy name> - AddExchangeLocationException "Kitty Petersen". It could take up to one day  for the exclusion to be applied. for more information about the time frame see: How long it takes for retention policies to take effect
To confirm that the policy distributed correctly after the exclusion, use the below commands:
Get-RetentionCompliancePolicy <Policy Name> -DistributionDetail | fl *distribution*, *exchangelocation*   

![image](https://user-images.githubusercontent.com/113264461/207303318-c5b1dd33-e138-4cf8-b9de-6c1faf00f270.png)

If there is an error in the distribution status, use the following command to redistribute the policy:
Set-RetentionCompliancePolicy -Identity <policy name> -RetryDistribution
The RetryDistribution switch specifies whether to redistribute the policy to all Exchange Online and SharePoint Online locations. You do not need to specify a value with this switch.
Check the delayed hold
After any type of hold is removed from a mailbox, a delay hold is applied. This means that the actual removal of the hold is delayed for 30 days. This gives admins an opportunity to search for or recover mailbox items that will be purged (purged) from the mailbox.
DelayHoldApplied: This feature is applied to email-related content in a user's mailbox. It will be True after the hold is removed; therefore, you need verify this parameter and disable it, if necessary, in order to clean the recoverable items folder.
Set-Mailbox <username> -RemoveDelayHoldApplied
Note: This scenario might apply to any folder, such as the inbox or any other folder, that you wish to clear using the legacy retention policy but the compliance retention policy prevents MFA from doing so.


Scenario 2: Restoring bulk deleted items that were deleted by mistake.

 Finally, if you have ever assigned a compliance retention policy to the incorrect mailbox or to multiple mailboxes by accident, this will result in bulk removal. For example, one of my customers applied a policy that deletes content after six months to the entire company instead of a single user, resulting in the bulk deletion of items older than six months. It was a massive task, but we were ultimately able to recover the deleted items by following the steps below:
To avoid processing the mailbox via MFA while restoring the deleted items, first disable ELC processing for the entire organization or for the impacted mailbox.
Set-OrganizationConfig –ELcProcessingDisabled $True
use PowerShell to recover deleted emails from the recoverable items folder and restore them to their original location:
You can restore the mail items based on the deletion date, for example:
Get-RecoverableItems -identity <User> -ResultSize unlimited -FilterItemType IPM.Note - FilterStartTime “dd/mm/yyyy” | Restore-RecoverableItems

 For more information:
·       Recover deleted messages in a user's mailbox in Exchange Online | Microsoft Docs
·       Get-RecoverableItems (ExchangePowerShell) | Microsoft Docs
·       Restore-RecoverableItems (ExchangePowerShell) | Microsoft Docs 

 I hope you find this information helpful when troubleshooting your next retention case.
