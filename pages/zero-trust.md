---
layout: default
title: Zero Trust
permalink: /pages/zero-trust/
---

<p style="font-size:0.85em;margin-bottom:1.5em;">
  <a href="/">← Home</a> &nbsp;&middot;&nbsp;
  <a href="/pages/identity-access/">Identity &amp; Access</a> &nbsp;&middot;&nbsp;
  <a href="/pages/exchange/">Exchange</a> &nbsp;&middot;&nbsp;
  <a href="/pages/automation/">Automation</a> &nbsp;&middot;&nbsp;
  <a href="/pages/compliance/">Compliance</a>
</p>

Implementation guides for Zero Trust architecture using Microsoft Entra ID, with direct mapping to DORA and BaFin BAIT regulatory requirements.

---

### Series: Zero Trust in Microsoft Entra ID

A four-part implementation blueprint for the hands-on professional. Each part maps to one of the core Zero Trust principles, with specific Entra ID configurations and DORA article mappings.

| Part | Principle | Status |
|------|-----------|--------|
| [Part 1 — Verify Explicitly](/zero-trust/2025/02/01/zero-trust-part1-verify-explicitly.html) | Verify Explicitly | Published |
| [Part 2 — Least Privilege Access](/zero-trust/2025/03/01/zero-trust-part2-least-privilege.html) | Least Privilege | Published |
| [Part 3 — Assume Breach](/zero-trust/2025/04/01/zero-trust-part3-assume-breach.html) | Assume Breach | Published |
| [Part 4 — DORA Compliance Mapping](/zero-trust/2025/05/01/zero-trust-part4-dora-mapping.html) | Full Audit Reference | Published |

---

{% for post in site.posts %}
{% if post.categories contains 'zero-trust' %}
### [{{ post.title }}]({{ post.url }})
*{{ post.date | date: "%B %d, %Y" }}*

{{ post.excerpt }}

---
{% endif %}
{% endfor %}

<p style="font-size:0.85em;margin-top:2em;">
  <a href="/">← Home</a> &nbsp;&middot;&nbsp;
  <a href="/pages/identity-access/">Identity &amp; Access</a> &nbsp;&middot;&nbsp;
  <a href="/pages/exchange/">Exchange</a> &nbsp;&middot;&nbsp;
  <a href="/pages/automation/">Automation</a> &nbsp;&middot;&nbsp;
  <a href="/pages/compliance/">Compliance</a>
</p>
