---
layout: default
title: "Zero Trust in Microsoft Entra ID — Part 1: Verify Explicitly"
date: 2025-02-01
categories: zero-trust
tags: [entra-id, conditional-access, mfa, dora, bafin, zero-trust]
excerpt: "A concrete implementation blueprint for the first Zero Trust principle — Verify Explicitly — with 14 specific Entra ID controls and direct DORA/BaFin regulatory mappings."
---

Zero Trust and regulatory frameworks like DORA are dominant forces in cybersecurity, but they often remain as high-level principles, leaving administrators with a critical question: *"What do I actually need to configure?"* The challenge is translating theory into tangible, auditable settings that form a truly secure posture.

This blog series cuts through the abstraction to provide a concrete implementation blueprint for Microsoft Entra ID. It is designed for the hands-on professional, whether you are preparing for a DORA audit or seeking a clear starting point for your Zero Trust journey. For those in regulated industries, we will map each control directly to DORA articles. For all security professionals, this series serves as a step-by-step guide to building a modern architecture, beginning with the foundational principle: **Verify Explicitly**.

> **A critical note on application:** The configurations in this series represent a strong security and compliance baseline. However, they are not a universal solution. Every organisation's infrastructure, business requirements, and risk tolerance are unique. Use this guide as a reference architecture, to be adapted through careful planning and tailored to your specific environment.

---

## What is "Verify Explicitly"?

At its core, "Verify Explicitly" means you never trust, you always verify. It dictates that every access request must be treated as originating from an untrusted network. Before granting access, every request is authenticated and authorised using multiple signals, including user identity, endpoint health, location, and the sensitivity of the resource being requested. This ensures that trust is never assumed — only earned for each individual session.

For a comprehensive overview of the principles, refer to [Microsoft's official Zero Trust guidance centre](https://learn.microsoft.com/en-us/security/zero-trust/).

---

## Core Settings for "Verify Explicitly" in Entra ID

To implement this principle, we will focus on the following 14 core settings within Microsoft Entra ID:

1. MFA via Conditional Access
2. Block Legacy Authentication
3. Secure the MFA Registration Page (My Security Info)
4. Phishing-Resistant MFA for Privileged Roles
5. User Risk Policy
6. Sign-In Risk Policy
7. Named Locations and Geo-blocking
8. Device Compliance as a Grant Condition
9. Authentication Methods Policy (Disabling Weak Methods)
10. Continuous Access Evaluation (CAE)
11. Password Policy
12. Token Protection
13. Block High-Risk Authentication Flows
14. Disable SSPR for Administrator Accounts

---

## 1. Multifactor Authentication (MFA) via Conditional Access

This is the foundational control to prove user identity by requiring a second factor of authentication (e.g., an authenticator app) before granting access. Microsoft's research found that enabling MFA blocks over 99.9% of automated account attacks, making it the single highest-impact control available. [Read more: One simple action you can take to prevent 99.9 percent of attacks on your accounts](https://www.microsoft.com/en-us/security/blog/2019/08/20/one-simple-action-you-can-take-to-prevent-99-9-percent-of-account-attacks/)

**Implementation:**

Create a Conditional Access policy that requires MFA for all users accessing all resources, while excluding designated emergency "break-glass" accounts. For detailed steps, see [Microsoft's documentation on configuring Conditional Access and MFA](https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-policy-all-users-mfa).

> **Note:** Enabling MFA alone is not sufficient if the user experience allows attackers to exploit it. Enable **number matching** in the Microsoft Authenticator app to prevent MFA fatigue attacks, where an attacker repeatedly sends push notifications hoping the user approves one. Additionally, enable **sign-in context** so users see the application name and location before approving. Enable the **"Report suspicious activity"** setting so users can flag unexpected MFA prompts directly — this feeds into Identity Protection as a risk signal. These settings are configured under **Protection > Authentication Methods > Microsoft Authenticator**.

**Regulatory Mapping — DORA:** Addresses Article 9(4)(d) by implementing a "strong authentication mechanism."

---

## 2. Block Legacy Authentication

This is arguably the most critical hardening step alongside MFA. It blocks older protocols (like POP3, IMAP, SMTP AUTH) that do not support MFA, effectively closing a major backdoor that bypasses nearly all modern security controls. Based on Microsoft's analysis, more than 97% of credential stuffing attacks and more than 99% of password spray attacks use legacy authentication protocols.

**Implementation:**

Create a Conditional Access policy that blocks access for client apps classified as "Other clients." Before enforcing, use the Sign-in logs to identify and remediate any legitimate use cases. See [Block legacy authentication with Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-policy-block-legacy-authentication).

**Regulatory Mapping — DORA:** Fully satisfies Article 9(4)(a and d) and 9(3). Legacy protocols inherently cannot support MFA. Blocking them is a prerequisite for enforcing strong authentication across the board.

---

## 3. Secure the MFA Registration Page (My Security Info)

Enforcing MFA is only effective if the registration process itself is protected. If an attacker compromises an account before MFA is registered, they can register their own authentication method and silently take over the account with no further barriers. This is a commonly overlooked gap that undermines the entire MFA deployment.

**Implementation:**

Create a Conditional Access policy that restricts access to the My Security Info page (user action: "Register security information") to trusted conditions only — for example, requiring a compliant device or a Temporary Access Pass (TAP) for initial registration. See: [Control security information registration with Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-policy-registration).

> **Note:** Use **Temporary Access Pass (TAP)** as the secure onboarding method for initial MFA registration. TAP is a time-limited, secure passcode issued by an administrator that allows a user to register their authentication methods without requiring an existing credential. This closes the bootstrapping problem — how do you securely register MFA for a user who has no MFA yet? Configure TAP under **Protection > Authentication Methods > Temporary Access Pass**.

**Regulatory Mapping — DORA:** Supports Article 9(4)(d) by ensuring the registration process for strong authentication methods is itself protected, closing a direct bypass of the MFA enforcement framework.

---

## 4. Phishing-Resistant MFA for Privileged Roles

Not all MFA methods are equal. SMS-based authentication is vulnerable to SIM-swapping, while standard authenticator apps remain susceptible to Adversary-in-the-Middle (AiTM) phishing where an attacker's proxy site relays your credentials in real time. Phishing-resistant methods like FIDO2 security keys and Windows Hello for Business prevent this by creating a cryptographic binding between the authentication request and the specific service, making relay attacks technically impossible.

**Implementation:**

This is achieved via a separate Conditional Access policy scoped to privileged roles, using the "Require authentication strength" grant control. See: [Conditional Access authentication strength documentation](https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-auth-strength-admin-mfa).

**Regulatory Mapping — DORA:** Directly satisfies Article 9(4)(c, d) concerning strong authentication for privileged and administrative access.

---

## 5. User Risk Policy

Leaked usernames and passwords often end up for sale on the dark web. Hackers use automated scripts to try different stolen username and password combinations to hijack accounts. This policy, part of Entra ID Protection, automatically detects and responds when a user's identity is determined to be at risk (e.g., their credentials appeared in a public breach).

**Implementation:**

Configure the policy to automatically enforce remediation — such as **Require risk remediation** — when user risk level is High. For passwordless users, Entra ID revokes sessions so they must reauthenticate. For users with passwords, they are prompted to complete a secure password change after successful MFA.

See: [Require remediation for risky users](https://learn.microsoft.com/en-us/entra/id-protection/howto-identity-protection-configure-risk-policies).

> **Note:** In hybrid environments where Entra ID is synchronised with on-premises Active Directory, the password reset remediation flow requires **Password Writeback** to be enabled in Entra Connect. Verify this configuration before enforcing the policy, otherwise users will be unable to self-remediate and will require Helpdesk intervention.

**Regulatory Mapping — DORA:** Helps satisfy Article 10(1) "mechanisms to promptly detect anomalous activities" and Article 11(2)(c) "activate, without delay, dedicated plans that enable containment measures."

---

## 6. Sign-In Risk Policy

Besides evaluating user risk, this policy evaluates each sign-in attempt in real-time for signs of risk (e.g., anonymous IP address, impossible travel) and enforces additional controls. Identity Protection sends risk signals to Conditional Access to make decisions and enforce organisational policies.

**Implementation:**

A common configuration is to require MFA for medium-risk sign-ins and block high-risk sign-ins entirely. See the link above for configuration details.

> **Note:** Before enforcing a block on High-risk sign-ins, review your organisation's Sign-in logs filtered by "High risk" for 30 days to assess the false positive rate. In environments with frequent international travel, a require-MFA response for High risk combined with an out-of-band Helpdesk process for confirmed false positives may be more operationally viable than a hard block.

**Regulatory Mapping — DORA:** Addresses Article 10(1) "mechanisms to promptly detect anomalous activities" and Article 10(2) "define alert thresholds and criteria to trigger and initiate ICT-related incident response processes."

---

## 7. Named Locations and Geo-blocking

This allows you to define trusted corporate network IP ranges and to create lists of countries from which access should be blocked.

**Implementation:**

After defining your locations, create a Conditional Access policy to enforce a block on traffic from high-risk countries. The goal is to reduce the attack surface, not to create MFA bypasses for trusted networks. See: [Conditional Access Policy: Using Network Signals](https://learn.microsoft.com/en-us/entra/identity/conditional-access/location-condition).

> **Note:** Named Locations should **not** be used as an MFA exclusion condition ("Skip MFA when on corporate network"). This configuration is frequently exploited by attackers who have compromised internal network access or are operating via VPN. MFA should be enforced regardless of network location. Named Locations are appropriate for blocking sign-ins from high-risk geographies, but should never serve as a trust bypass for MFA requirements.

**Regulatory Mapping — DORA:** Supports Article 9(4)(f) regarding network and infrastructure management using appropriate techniques to reduce attack surface based on a risk assessment of geographic threat vectors.

---

## 8. Device Compliance as a Grant Condition

The health and management state of the device used to access corporate resources is a critical, and often overlooked, security signal. This control ensures that access is only granted from devices that are managed (e.g., via Intune) and meet your corporate security standards (e.g., encrypted, antivirus enabled).

**Implementation:**

This requires both setting up compliance policies in Intune and creating a Conditional Access policy that includes the "Require device to be marked as compliant" grant control. See: [Require Device Compliance with Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-policy-compliant-device).

**Regulatory Mapping — DORA:** Satisfies Article 9(4)(d) and Article 8(1) regarding endpoint security and management of ICT assets, as well as Article 9(2) regarding high standards of availability, authenticity, integrity, and confidentiality of data.

---

## 9. Authentication Methods Policy (Disabling Weak Methods)

For a truly secure posture, you must phase out and disable weaker methods like SMS and voice calls. These methods are vulnerable to attacks like SIM-swapping and lack the security of modern, app-based authenticators.

**Implementation:**

Depending on your organisation's requirements, disable weaker methods like SMS and voice calls if you are using passwordless and Windows Hello as preferred methods. See: [Manage authentication methods](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-authentication-methods-manage).

> **Note:** Some tenants still have legacy per-user MFA settings active in parallel with the Authentication Methods Policy. When both are active, they are evaluated with an OR condition — meaning a weaker method enabled in the legacy policy remains available to users even if it is disabled in the Authentication Methods Policy. Verify your migration status under **Protection > Authentication Methods > Policies > Migration settings** and complete the migration to ensure the Authentication Methods Policy is the single source of truth.

**Regulatory Mapping — DORA:** Addresses Article 9(4)(a) by defining the organisational policy for strong authentication, and Article 9(4)(d) by ensuring only cryptographically strong methods are available.

---

## 10. Continuous Access Evaluation (CAE)

CAE enables near-real-time enforcement of security events. If a user is disabled or a high-risk event is detected, CAE revokes their access tokens almost instantly, rather than waiting for them to expire.

**Implementation:**

CAE is enabled by default in licensed tenants, but its effectiveness depends on blocking legacy authentication and having active risk policies. [Learn more about Continuous Access Evaluation](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-continuous-access-evaluation).

> **Note:** CAE is only effective for workloads whose client applications support the CAE protocol. First-party Microsoft services (Exchange Online, SharePoint Online, Teams, MS Graph) are CAE-capable. Third-party SaaS applications connected via Entra SSO do not participate in CAE revocation events. Administrators should not assume CAE provides universal near-real-time revocation across all connected applications.

**Regulatory Mapping — DORA:** Satisfies Article 9(4)(b) and 9(4)(e) by providing continuous monitoring and a "prompt response to security events," and Article 11(2)(c) "activate, without delay, dedicated plans that enable containment measures."

---

## 11. Password Policy

MFA is your primary control, but it only covers the second factor. A weak password still undermines the entire authentication chain. There is little value in requiring MFA if a user's password is "Summer2024!" — it means one factor is already effectively compromised before the session even begins.

**Implementation:**

Leverage the **custom banned password list** to block company-specific terms, project names, or local slang that attackers might guess. Enable **Entra ID Password Protection** and ensure Smart Lockout settings are correctly configured to mitigate password spray attacks. See: [Combined password policy and check for weak passwords](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-password-ban-bad-combined-policy).

> **Note:** Microsoft's current guidance recommends **disabling password expiration** for accounts protected by MFA and breach detection. Forced periodic password changes have been shown to produce weaker passwords over time, as users follow predictable patterns like incrementing a number or changing a season. When Entra ID Password Protection, breach detection via Identity Protection, and MFA are all in place, the risk that a compromised password goes undetected long enough to justify forced rotation is significantly reduced.

**Regulatory Mapping — DORA:** Article 9(4)(d) requires "strong authentication mechanisms." Password protection ensures the first authentication factor is not trivially compromised.

---

## 12. Token Protection (Conditional Access Session Control)

MFA protects the authentication step, but not what happens after. Once a user authenticates, Entra ID issues tokens that grant ongoing access. If an attacker steals a token through AiTM phishing or malware, they can replay it without needing credentials or MFA. Token Protection addresses this by cryptographically binding the Primary Refresh Token (PRT) to the specific device it was issued on, making a stolen token useless without the device itself.

According to Microsoft's Digital Defense Report 2024, AiTM phishing attacks rose 146% year-over-year.

**Implementation:**

Create a Conditional Access policy with the session control "Require token protection for sign-in sessions," scoped to Exchange Online, SharePoint Online, and Teams. Requires Entra ID P1 and Windows 10 or later devices that are Entra joined, hybrid joined, or registered. Deploy in report-only mode first. See: [How Token Protection Enhances Conditional Access Policies](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-token-protection).

> **Note:** Token Protection currently applies to client applications only, not browser sessions. A stolen session cookie in a browser remains outside the scope of this control. It does not cover third-party SaaS applications.

**Regulatory Mapping — DORA:** Supports Article 9(4)(d) by extending strong authentication guarantees beyond the initial sign-in to the session layer, and Article 9(4)(b) regarding continuous verification of access integrity.

---

## 13. Block High-Risk Authentication Flows

Device code flow — designed for input-constrained devices — has become an active phishing vector. An attacker tricks a user into entering a device code at microsoft.com/devicelogin, handing over a fully authenticated session including completed MFA, without the user visiting any suspicious site. Authentication transfer carries similar risk: a QR code in desktop Outlook transfers an authenticated session to a mobile device, potentially bypassing device compliance controls.

**Implementation:**

Create a Conditional Access policy to block the device code flow. See: [Block authentication flows with Conditional Access policy](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-block-authentication-flows).

> **Note:** Review Sign-in logs filtered by "Original transfer method: Device code flow" to identify any legitimate use cases before enforcing. If device code flow is required for specific devices (e.g., conference room displays on a trusted network), create a scoped exception for those devices and locations rather than a broad exemption.

**Regulatory Mapping — DORA:** Addresses Article 9(4)(a) and 9(4)(d) by eliminating authentication flows that cannot be controlled or audited — the same principle that justifies blocking legacy authentication.

---

## 14. Disable Self-Service Password Reset (SSPR) for Administrator Accounts

By default, administrator accounts can use SSPR to reset their own passwords. While Microsoft enforces a mandatory two-gate policy for admins requiring two authentication factors, the SSPR flow for admin accounts cannot be customised and does not enforce phishing-resistant methods. For organisations that have deployed phishing-resistant authentication for privileged roles, SSPR for admins becomes unnecessary and introduces an authentication path that bypasses stronger controls.

**Implementation:**

SSPR for administrators cannot be disabled via the Entra portal. Use the Microsoft Graph PowerShell cmdlet:

```powershell
Update-MgPolicyAuthorizationPolicy -AllowedToUseSspr:$false
```

Before disabling, ensure an alternative credential recovery process is documented for admin accounts. See: [Self-service password reset policies](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-sspr-policy).

**Regulatory Mapping — DORA:** Supports Article 9(4)(c) and 9(4)(d) by ensuring that privileged account credential recovery meets the same authentication standard as initial access, closing a potential bypass in the privileged access control framework.

---

## Conclusion

If you are just beginning your Zero Trust journey, start with two controls: enforce MFA via Conditional Access and block legacy authentication. These two settings alone address the most common attack vectors and form the foundation everything else depends on. The remaining controls build on that foundation to create a posture that is not only technically sound, but auditable.

The next article covers the second Zero Trust principle: **Use Least Privilege Access**.

---

*[← Back to Zero Trust Series](/pages/zero-trust/) · [Part 2: Use Least Privilege Access →](/posts/2025-03-01-zero-trust-part2-least-privilege)*
