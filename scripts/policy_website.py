"""Render policy content inside the existing MARC website shell, preserving its design."""
import html
import re


def website_policy(text, policy):
    escape = html.escape
    replacements = [
        (r'(<h1 id="policy-title">).*?(</h1>)', escape(policy['title'])),
        (r'(<p class="policy-date">).*?(</p>)', 'Last updated: ' + escape(policy['effectiveDate'])),
        (r'(<p class="policy-intro">).*?(</p>)', escape(policy['introduction'])),
        (r'(<aside class="policy-summary"[^>]*>).*?(</aside>)',
         '<h2 id="policy-summary-title">At a glance</h2><ul>' +
         ''.join('<li>' + escape(item) + '</li>' for item in policy['summary']) +
         '</ul><p>This summary is a guide to the full document below.</p>'),
        (r'(<nav aria-label="On this page">).*?(</nav>)',
         ''.join('<a href="#' + escape(s['id'], quote=True) + '"><span>' + str(i).zfill(2) +
                 '</span>' + escape(s['title']) + '</a>' for i, s in enumerate(policy['sections'], 1)))
    ]
    for pattern, content in replacements:
        text, count = re.subn(pattern, lambda m: m[1] + content + m[2], text, count=1, flags=re.S)
        if count != 1:
            raise ValueError('Unrecognized MARC policy layout: ' + pattern)
    sections = []
    for i, section in enumerate(policy['sections'], 1):
        key = escape(section['id'], quote=True)
        content = '<section aria-labelledby="' + key + '"><h2 id="' + key + '"><span class="policy-number">' + str(i) + '.</span> ' + escape(section['title']) + '</h2>'
        content += ''.join('<p>' + escape(p) + '</p>' for p in section['paragraphs'])
        if section['links']:
            content += '<div class="policy-links">' + ''.join('<a href="' + escape(link['url'], quote=True) + '">' + escape(link['title']) + ' ↗</a>' for link in section['links']) + '</div>'
        sections.append(content + '</section>')
    text, count = re.subn(r'<section aria-labelledby="[^\"]+">.*?(?=<div class="policy-end">)', lambda _: '\n'.join(sections) + '\n\n', text, count=1, flags=re.S)
    if count != 1:
        raise ValueError('Policy sections or footer marker not found.')
    return text
