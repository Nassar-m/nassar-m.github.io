---
layout: page
title: Zero Trust
permalink: /pages/zero-trust/
---

Implementation guides for Zero Trust architecture using Microsoft Entra ID, with direct mapping to DORA and BaFin BAIT regulatory requirements.

---

### Series: Zero Trust in Microsoft Entra ID

A four-part implementation blueprint for the hands-on professional. Each part maps directly to one of the four core Zero Trust principles, with specific Entra ID configurations and their corresponding DORA articles.

| Part | Principle | Status |
|------|-----------|--------|
| [Part 1 — Verify Explicitly](/posts/2025-02-01-zero-trust-part1-verify-explicitly) | Verify Explicitly | Published |
| [Part 2 — Use Least Privilege Access](/posts/2025-03-01-zero-trust-part2-least-privilege) | Least Privilege | Coming Soon |
| [Part 3 — Assume Breach](/posts/2025-04-01-zero-trust-part3-assume-breach) | Assume Breach | Coming Soon |
| [Part 4 — DORA Compliance Mapping](/posts/2025-05-01-zero-trust-part4-dora-mapping) | Full Audit Reference | Coming Soon |

---

{% for post in site.posts %}
{% if post.categories contains 'zero-trust' %}
### [{{ post.title }}]({{ post.url }})
*{{ post.date | date: "%B %d, %Y" }}*

{{ post.excerpt }}

---
{% endif %}
{% endfor %}
