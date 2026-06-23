---
layout: post
title: Zero Trust in Microsoft Entra ID, Part 2 - Use Least Privilege Access
date: 2026-06-23
categories: [Zero Trust]
tags: [entra-id, pim, least-privilege, identity-governance, dora, zero-trust]
excerpt: Eight steps to limit standing access by scope and time, each mapped to the DORA RTS articles a supervisor will test you against.
---

Part 1 covered the first Zero Trust principle, Verify Explicitly: authenticate and risk-assess every access request before it goes through. That answers *who* is asking. This part deals with the next question, which is how much you hand them once they're through the door.

The second principle is Use Least Privilege Access. The goal is to limit standing access by both scope and time: just-in-time, just-enough access for admins, right-sized permissions for users, apps, and guests, and governance that keeps it correct as the tenant changes.

> **A note before the steps:** The settings in this series are a strong baseline, not a universal answer. Treat them as a reference architecture you adapt to your own environment, licensing, and risk appetite. Every tenant is a little different, and a good design accounts for that.

---

## The action plan

1. Stand up the Enterprise Access Model.
2. PIM for everything privileged.
3. Right-size privileged roles.
4. Make consent and app permissions least privilege.
5. Restrict who can create and register apps and subtenants.
6. Least privilege for external and guest access.
7. Identity Governance.
8. Protect privileged operations and policy integrity.

---

## 1. Stand up the Enterprise Access Model (Control Plane)

Replace the legacy AD tier model. Start by defining your Control Plane: Entra roles, Entra Connect and sync, federation, PIM, Conditional Access, and the Azure resources Entra depends on.

One rule holds the whole thing together: you should never be able to take control of a higher plane from a lower one. A helpdesk admin who can reset a Global Administrator's credentials holds control-plane power, whatever the job title says. So least privilege starts with a single question for each identity: which plane does it belong to, and what is the smallest footprint it needs there? Map that first and the rest of the plan gets a lot easier.

**Do this:**

- Make privileged admins cloud-native. No synced on-prem accounts in privileged roles.
- Allow highly privileged activation only from a PAW/SAW, enforced with a Conditional Access device-filter policy.
- Give Global Admins no standing access to Azure management groups or subscriptions. Azure resources and identity-governance subscriptions stay reachable only through privileged roles.
- Lock the Entra Connect sync account to service-principal credentials and a named location.

**Regulatory Mapping — DORA:** This is Article 8 in practice. You identify the identities that control your critical functions and draw a boundary around them. The "no escalation from a lower plane" rule is the segregation-of-duties requirement from RTS Article 21, applied to the directory itself.

**Microsoft reference:**

- [Securing privileged access Enterprise access model](https://learn.microsoft.com/en-us/security/privileged-access-workstations/privileged-access-access-model)
- [Rapidly modernize your security infrastructure (RaMP)](https://learn.microsoft.com/en-us/security/privileged-access-workstations/security-rapid-modernization-plan)
- [Deploying a privileged access solution](https://learn.microsoft.com/en-us/security/privileged-access-workstations/privileged-access-deployment)
- [Protect Microsoft 365 from on-premises attacks](https://learn.microsoft.com/en-us/entra/architecture/protect-m365-from-on-premises-attacks)

---

## 2. PIM for everything privileged

This is the single most important control. PIM replaces permanent admin roles with just-in-time access: privileges activate on demand, for a limited time, after a justification and an MFA check, with approval where you require it.

**Do this:**

- Onboard every privileged role into PIM as eligible, not active.
- Require MFA and justification on activation.
- Require an approval workflow for Global Administrator.
- Cap activation duration (2–8 hours is typical).
- Flatten nested groups in PIM for Groups so eligibility stays explicit.
- Keep two cloud-only break-glass accounts out of PIM and Conditional Access so a PIM or MFA outage can't lock you out. Monitor them closely.

**Regulatory Mapping — DORA:** RTS Article 21 requires privileged access on a need-to-use basis with strong authentication, and it explicitly calls for automated privileged-access-management tooling and named handling of emergency access. PIM is exactly that: no standing admin rights, elevation only when there's a task, MFA at the moment it matters, and break-glass accounts as the controlled exception.

**Microsoft reference:** [Plan a Privileged Identity Management deployment](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-deployment-plan)

---

## 3. Right-size privileged roles

PIM controls *when* someone has a role. This step controls *who* holds it and how broad it is.

**Do this:**

- Keep Global Administrators below eight (CIS recommends 2–4) and use least-privileged built-in or custom roles instead of GA wherever you can.
- Keep total privileged role assignments under ten. Entra shows a warning on the Roles and administrators page once you pass that.
- Remove guests and workload identities from privileged roles.
- Strip privilege from inactive apps and stale identities.
- Attach an access review to every privileged role.

**Regulatory Mapping — DORA:** This is least privilege from RTS Article 21 at its most direct: fewer broad grants, narrower scopes. Removing guests, app identities, and stale accounts, then reviewing what's left, is the account-management duty the same article spells out (grant, review, revoke).

**Microsoft reference:** [Best practices for Microsoft Entra roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices)

---

## 4. Make consent and app permissions least privilege

Apps are identities too, and they are often the most over-permissioned ones in the tenant.

**Do this:**

- Set user consent to verified-publisher and low-risk permissions only, or turn it off entirely.
- Enable the admin-consent workflow so requests get reviewed instead of silently approved.
- Restrict resource-specific consent.
- Require explicit user assignment (and scoped provisioning) on enterprise apps.
- Assign owners to enterprise apps, especially any with high-privilege Graph permissions.
- Turn on provisioning where it's supported.

**Regulatory Mapping — DORA:** An app with broad Graph permissions is an over-privileged identity. This applies least privilege (RTS Article 21) and unique, governed identity (RTS Article 20) to non-human principals. And because third-party OAuth apps are external ICT services, governing consent is also part of third-party risk under Article 28. You're stopping users from quietly onboarding outside services.

**Microsoft reference:** [Configure how users consent to applications](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/configure-user-consent)

---

## 5. Restrict who can create and register apps and subtenants

If anyone can mint a service principal or spin up a subtenant, you've lost control of your identity inventory.

**Do this:**

- Set "Users can register applications" to No, and limit app and service-principal creation to privileged roles.
- Restrict tenant creation to the Tenant Creator role.

**Regulatory Mapping — DORA:** RTS Article 20 expects a unique, governed set of identities, and Article 21 expects access boundaries you actually control. Letting any user create new security principals or tenants breaks both, because you can't govern identities you didn't know were created.

**Microsoft reference:** [Default user permissions in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/users-default-permissions)

---

## 6. Least privilege for external and guest access

Guests and partners are identities you don't fully control, so default them to the least access that still lets them do their job.

**Do this:**

- Configure cross-tenant access settings (inbound and outbound) and B2B allow/deny domain lists, and limit guest collaboration to approved tenants.
- Deploy tenant restrictions v2 (via Global Secure Access or managed devices) to stop data leaking to other tenants from your network and devices.
- Set guest permissions to the most restrictive directory-object level.
- Disable guests-inviting-guests, guest app ownership, and self-service sign-up.
- Enforce GDAP least privilege for partners.

**Regulatory Mapping — DORA:** The same need-to-use and least privilege from RTS Article 21, applied to identities that live outside your walls. Partner access through GDAP also falls under third-party risk (Article 28), since you're bounding what an external administrator can reach.

**Microsoft reference:** [Cross-tenant access settings](https://learn.microsoft.com/en-us/entra/external-id/cross-tenant-access-settings-b2b-collaboration)

---

## 7. Identity Governance

This is where least privilege stops being a one-time cleanup and becomes a process that holds.

**Do this:**

- Move access behind entitlement-management access packages with expiration, approval, connected organizations for externals, and built-in access reviews.
- Require a sponsor for every guest, and lifecycle-manage guests with access reviews.
- Make sure all app assignments and group memberships are governed, not ad-hoc.

**Regulatory Mapping — DORA:** Access packages deliver the identity lifecycle of RTS Article 20, and access reviews deliver the periodic review of RTS Article 21, including the at-least-every-six-months review for systems behind critical or important functions. This is the primary technical control for that review obligation, so set the cadence to meet it. Quarterly is a comfortable margin.

**Microsoft reference:** [Review access of an access package in entitlement management](https://learn.microsoft.com/en-us/entra/id-governance/entitlement-management-access-reviews-review-access)

---

## 8. Protect privileged operations and policy integrity

Least privilege means nothing if a mid-tier admin can quietly rewrite the policies that enforce it. So protect the controls themselves.

**Do this:**

- Enable protected actions so changing Conditional Access (and cross-tenant settings) requires a CA-satisfied step-up.
- Put the groups your CA policies reference into a restricted-management administrative unit so they can't be tampered with from outside that scope.
- Restrict non-admin BitLocker key recovery, and manage local admins on Entra-joined devices.

**Regulatory Mapping — DORA:** RTS Article 21 is about restricting access to your assets, and the access controls are themselves critical assets. Protecting their integrity is also a governance duty under Article 5 / RTS Article 3: the management body has to be able to trust that the framework it approved is the one actually running. Protected actions and restricted-management AUs make sure changes to the controls require privilege and leave a record.

**Microsoft reference:** [Restricted management administrative units in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/admin-units-restricted-management)

---

## How this maps to DORA (read this once)

Rather than repeat the regulation under every control, here's the short version. Everything above traces back to these:

- **DORA Article 8 — know your assets.** You identify your ICT assets and map them to the critical business functions they support. This is what makes your privileged-access inventory a regulatory requirement rather than just good hygiene.
- **DORA Article 9 — protect them.** The umbrella obligation to control access to those assets. Every control here lives under it.
- **RTS (EU) 2024/1774, Article 20 — Identity management.** Every person and every system gets a unique identity, managed across its full lifecycle. This is why shared accounts, ungoverned app identities, and orphaned guests are problems.
- **RTS (EU) 2024/1774, Article 21 — Access control.** Access follows need-to-know, need-to-use, and least privilege. Duties are segregated. Privileged and emergency access is granted only on a need-to-use basis, with strong authentication. Access rights are reviewed at least every six months for systems supporting critical or important functions.
- **DORA Article 28 — third-party risk.** Covers the external apps and partners that touch your tenant.
- **DORA Article 5 (and RTS Article 3) — governance.** The management body owns the ICT risk framework and has to be able to oversee it. This is why the controls themselves have to be tamper-resistant.

The RTS (the Level 2 detail under DORA) is what a supervisor actually tests you against, so each control above points to the specific RTS article and explains why it satisfies it.

---

## Wrapping up

Worked through in order, these eight steps shrink your attack surface and line up cleanly with DORA's access-control requirements, mainly Articles 20 and 21 of the RTS.

One last thing, because it's usually where these programs succeed or fail: the most secure control is the one your admins are happy to use. Rolling out passwordless sign-in, whether Windows Hello for Business or FIDO2 keys, makes activating PIM or clearing an MFA prompt almost frictionless. When the secure path is also the easy path, people take it.

Part 3 covers the last principle, Assume Breach, including Privileged Access Workstations and the monitoring that keeps those break-glass accounts honest.
