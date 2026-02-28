---
layout: default
title: "ZeroKnown"
---

Notes on M365 security — what actually gets configured, not just what the frameworks say.

---

### Browse by Topic

| Topic | Focus |
|-------|-------|
| [**Identity & Access**](/pages/identity-access/) | Entra ID &middot; Conditional Access &middot; PIM &middot; Lifecycle management |
| [**Zero Trust**](/pages/zero-trust/) | Architecture &middot; DORA/BaFin mapping &middot; Implementation guides |
| [**Exchange & Messaging**](/pages/exchange/) | Exchange Online &middot; Mail flow &middot; Retention |
| [**Automation**](/pages/automation/) | PowerShell &middot; Graph API &middot; Workflow automation |
| [**Compliance**](/pages/compliance/) | DORA &middot; BaFin BAIT &middot; Audit readiness |

---

### Posts

{% for post in site.posts %}
### [{{ post.title }}]({{ post.url }})
*{{ post.date | date: "%B %d, %Y" }}*

{{ post.excerpt }}

---
{% endfor %}
