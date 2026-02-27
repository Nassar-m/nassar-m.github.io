---
layout: page
title: Compliance
permalink: /pages/compliance/
---

Regulatory compliance guides for European financial institutions — DORA, BaFin BAIT, and audit readiness using Microsoft security controls.

---

{% for post in site.posts %}
{% if post.categories contains 'compliance' %}
### [{{ post.title }}]({{ post.url }})
*{{ post.date | date: "%B %d, %Y" }}*

{{ post.excerpt }}

---
{% endif %}
{% endfor %}

*More articles coming soon. Topics in progress: BaFin BAIT full control mapping, DORA ICT incident classification, and audit evidence collection.*
