---
layout: post
title: Zero Trust in Microsoft Entra ID, Part 2 - Use Least Privilege Access
date: 2026-06-23
categories: [Zero Trust]
tags: [entra-id, pim, least-privilege, identity-governance, dora, zero-trust]
excerpt: Eight steps to limit standing access by scope and time, each mapped to the DORA RTS articles a supervisor will test you against.
---

This is the final article in the series. Part 1 built the secure front door with *Verify Explicitly*. Part 2 cut down the internal attack surface with *Use Least Privilege Access*. This part deals with what happens when an attacker gets past both, which is the point of the third Zero Trust principle: **Assume Breach**.

> **A note before the steps:** The configurations here are a strong security and compliance baseline, not a drop-in solution for every tenant. Treat the guide as a reference architecture and adapt it to your own environment through your own planning.

---

## What "Assume Breach" means

The shift is from trying to build an unbreakable wall to accepting that a breach will eventually happen, then designing so it does as little damage as possible. You contain the blast radius, detect intruders quickly, and automate enough of the response to limit the damage before a person can step in.

A submarine is the right mental model. When one compartment floods, the watertight doors seal it off so the rest of the vessel stays afloat.

The eight controls below are ordered by how much they matter for detection and response.

---

## 1. Log export and SIEM integration (highest priority)

**What to do.** You can't detect what you can't see, so this is the foundation for everything else in the article. Configure Entra ID Diagnostic Settings to stream all relevant log categories into Microsoft Sentinel (through a Log Analytics workspace) or a third-party SIEM such as Splunk (through an Event Hub). At a minimum, send `SignInLogs`, `AuditLogs`, `NonInteractiveUserSignInLogs`, and `ServicePrincipalSignInLogs`. Set retention to at least one year.

**Regulatory Mapping — DORA.** This satisfies Article 10 (detection) and Article 12 (logging and retention). Article 10 requires mechanisms to promptly detect anomalous activity, and you can't do that without the logs. Article 12 treats those logs as data that must be retained and available for forensic analysis, which is where the one-year minimum comes from. Every other control here depends on these logs existing and being searchable.

**Microsoft reference:** [Integrate Microsoft Entra logs with Azure Monitor logs](https://learn.microsoft.com/en-us/entra/identity/monitoring-health/howto-integrate-activity-logs-with-azure-monitor-logs)

---

## 2. Sentinel analytics rules for identity threats (high)

**What to do.** Once logs are flowing, turn them into detections. Enable the built-in Sentinel analytics rules for Entra ID and add custom ones for your environment. Good starting examples: a privileged role assigned outside PIM, bulk user deletion, MFA disabled for a user, and sign-in from a known malicious IP. Configure these to raise high-severity incidents automatically.

**Regulatory Mapping — DORA.** This delivers the threat detection capability in Article 10 and produces the trigger for Article 17 (incident classification and reporting). Without scheduled rules actively looking for attack patterns, the logs from control 1 just sit there.

**Microsoft reference:** [Threat detection in Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/threat-detection)

---

## 3. Automated "closed-loop" remediation (high)

**What to do.** Detection alone isn't enough; response speed decides how bad an incident gets. Wire a detection signal (for example, a high-risk user alert from Identity Protection) to an automated action. A common pattern is a Sentinel automation rule that runs a Logic App playbook to call the Graph API, disable the account, and open a critical incident for SOC review. This collapses the response window from hours to seconds.

**Regulatory Mapping — DORA.** This addresses Article 10(2) (automated response) and helps you hit the tight timelines in Article 17(3). Automation closes the gap between "we detected it" and "we contained it."

**Microsoft reference:** [Automate threat response with playbooks in Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/automation/automate-responses-with-playbooks)

---

## 4. Break-glass account monitoring (high)

**What to do.** Emergency access accounts are a double-edged sword. They keep you from locking yourself out, but a sign-in from one is a high-fidelity signal of either a real emergency or a serious breach. Create a high-severity Sentinel rule that fires an immediate incident and pages the on-call SOC whenever a break-glass account signs in. Test the alert quarterly.

**Regulatory Mapping — DORA.** This supports Article 11 (response and business continuity) and Article 10 (detecting unauthorized use of emergency accounts). The quarterly test is also your audit evidence that the control actually works.

**Microsoft reference:** [Manage emergency access accounts in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access)

---

## 5. App protection policies (MAM) for data containment (medium-high)

**What to do.** This contains corporate data on unmanaged personal devices (BYOD). In Intune, create App Protection Policies that wrap a managed, encrypted container around apps like Outlook and Teams: block copy/paste to unmanaged apps, require a PIN, and block backups to personal cloud storage. Enforce it with a Conditional Access policy that requires an approved client app or an app protection policy on mobile.

**Regulatory Mapping — DORA.** This addresses Article 9(3) (minimizing the impact of an incident) and Article 9(4)(d) (endpoint controls). If a personal device is compromised, the policy keeps the corporate data sealed off from the rest of the device.

**Microsoft reference:** [Require an approved client app or app protection policy with Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-approved-app-or-app-protection)

---

## 6. Privileged Access Workstations (PAWs) (medium-high)

**What to do.** As mentioned in Part 2, a PAW is a dedicated, hardened device used only for sensitive admin work. This keeps privileged sessions away from the higher-risk environment of a daily-use machine. Build a strict hardened configuration profile in Intune, then require a compliant PAW in Conditional Access before a user can activate a privileged role in PIM.

**Regulatory Mapping — DORA.** This supports Article 9(3) by containing the damage from a compromised standard workstation, and Article 9(4)(d) for endpoint security. An admin's regular laptop is a far bigger target than a locked-down PAW; separating the two limits what a compromised endpoint can reach.

**Microsoft reference:** [Deploying a privileged access solution](https://learn.microsoft.com/en-us/security/privileged-access-workstations/privileged-access-deployment)

---

## 7. Conditional Access session controls (medium)

**What to do.** These limit the value of a stolen session token. Set "Persistent browser session" to **Never**, and use "Sign-in frequency" to force periodic re-authentication, for example every 8 hours on managed devices and every hour on unmanaged ones.

**Regulatory Mapping — DORA.** This addresses Article 9(3) (impact minimization) and Article 9(4)(a) (session management). A token an attacker steals is only useful until it expires, so shorter sessions shrink the window of exposure.

**Microsoft reference:** [Conditional Access adaptive session lifetime policies](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-session-lifetime)

---

## 8. Cross-tenant access restrictions (medium)

**What to do.** Apply Assume Breach to your business partners instead of trusting their tenant's security blindly. In Cross-tenant access settings, set the inbound defaults to block access and to not trust MFA or device compliance from external tenants. Then add explicit allow entries for partners you trust. Guests are now forced to satisfy your policies, not their own.

**Regulatory Mapping — DORA.** This is a key control for Article 28 (ICT third-party risk). A partner's weak security shouldn't become your problem; this control puts your standards in front of every guest.

**Microsoft reference:** [Cross-tenant access overview](https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-overview)

---

## Suggested order

If you're rolling this out alongside Parts 1 and 2, get the break-glass accounts in place first so you can't lock yourself out, then turn on log export and the triage rhythm, then layer the detection rules, automation, and containment controls on top. Detection and logging come before automation, because automation is only as good as the signals feeding it.

---

## Series conclusion

Across the three articles, we verified every user at the front door (*Verify Explicitly*), handed out only the keys each person actually needed (*Use Least Privilege Access*), and set up alarms and internal bulkheads for the day an intruder gets in (*Assume Breach*).

This isn't a project you finish once. It's a cycle you keep tightening. But building on a Zero Trust foundation gives you two things at the same time: an environment that holds up against modern threats, and the clear, auditable evidence you need to show DORA compliance.
