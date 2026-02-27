---
layout: page
title: Automation
permalink: /pages/automation/
---

PowerShell scripts, Microsoft Graph API guides, and workflow automation for identity and messaging administration.

---

{% for post in site.posts %}
{% if post.categories contains 'automation' %}
### [{{ post.title }}]({{ post.url }})
*{{ post.date | date: "%B %d, %Y" }}*

{{ post.excerpt }}

---
{% endif %}
{% endfor %}

*More articles coming soon. Topics in progress: Graph API bulk operations, automated access reviews, and lifecycle management scripts.*
