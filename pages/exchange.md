---
layout: page
title: Exchange & Messaging
permalink: /pages/exchange/
---

Practical guides on Exchange Online administration, mail flow architecture, retention policies, PGP encryption, and third-party migrations.

---

{% for post in site.posts %}
{% if post.categories contains 'exchange' %}
### [{{ post.title }}]({{ post.url }})
*{{ post.date | date: "%B %d, %Y" }}*

{{ post.excerpt }}

---
{% endif %}
{% endfor %}

*More articles coming soon. Topics in progress: Hybrid mail flow, connectors, and compliance archiving.*
