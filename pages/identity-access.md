---
layout: page
title: Identity & Access
permalink: /pages/identity-access/
---

Articles on Microsoft Entra ID configuration, application consent policies, Conditional Access, Privileged Identity Management, and identity lifecycle management.

---

{% for post in site.posts %}
{% if post.categories contains 'identity-access' %}
### [{{ post.title }}]({{ post.url }})
*{{ post.date | date: "%B %d, %Y" }}*

{{ post.excerpt }}

---
{% endif %}
{% endfor %}

*More articles coming soon. Topics in progress: Entra ID PIM configuration, Access Reviews, and SSPR policy design.*
