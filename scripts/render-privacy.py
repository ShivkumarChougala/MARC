"""Render public policy copies from the document bundled with MARC. No network requests."""
from pathlib import Path
import argparse
import html
import json

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--check", action="store_true")
args = parser.parse_args()
outputs = {}
for resource, stem in [("MARCPrivacyPolicy", "privacy"), ("MARCTermsOfUse", "terms")]:
    policy = json.loads((root / ("MARC/Resources/" + resource + ".json")).read_text())
    escape = html.escape
    markdown = ["# " + policy["title"], "Effective " + policy["effectiveDate"], policy["introduction"], "Contact: " + policy["contactEmail"], "Published version: " + policy["publishedURL"]]
    sections = []
    for section in policy["sections"]:
        markdown.extend(["## " + section["title"], *section["paragraphs"]])
        content = "".join("<p>" + escape(text) + "</p>" for text in section["paragraphs"])
        for link in section["links"]:
            markdown.append("[" + link["title"] + "](" + link["url"] + ")")
            content += '<p><a href="' + escape(link["url"], quote=True) + '">' + escape(link["title"]) + '</a></p>'
        sections.append('<section aria-labelledby="' + escape(section["id"]) + '"><h2 id="' +
                        escape(section["id"]) + '">' + escape(section["title"]) + '</h2>' + content + '</section>')
    page = '''<!doctype html>
    <html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
    <title>__POLICY_TITLE__</title><meta name="description" content="MARC app policies for connections, files, optional AI and support.">
    <style>
    :root{color-scheme:light dark;font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;line-height:1.7;background:#fafafa;color:#222}
    body{margin:0}main{max-width:760px;margin:auto;padding:44px 22px 72px}h1{font-size:clamp(1.8rem,5vw,2.5rem);line-height:1.2;letter-spacing:-.04em}h2{font-size:1.25rem;line-height:1.4;margin:0 0 16px}p{overflow-wrap:anywhere}section{margin-top:36px}a{color:#a73345;text-underline-offset:3px}a:focus-visible{outline:3px solid currentColor;outline-offset:4px}.date{color:#666}.brand{font-size:.8rem;font-weight:700;letter-spacing:.18em}
    @media(prefers-color-scheme:dark){:root{background:#141416;color:#eee}a{color:#ff9da9}.date{color:#aaa}}@media print{main{padding:0}a{color:inherit}}
    </style></head><body><main><div class="brand">MARC</div>
    '''
    page = page.replace('__POLICY_TITLE__', escape(policy['title']))
    page += '<h1>' + escape(policy["title"]) + '</h1><p class="date">Effective ' + escape(policy["effectiveDate"]) + '</p>'
    page += '<p>' + escape(policy["introduction"]) + '</p><p>Contact: ' + escape(policy['contactEmail']) + '</p><p><a href="' + escape(policy['publishedURL'], quote=True) + '">Published version</a></p>' + "\n".join(sections) + '\n</main></body></html>\n'
    outputs.update({root / ("docs/" + stem.upper() + ".md"): "\n\n".join(markdown) + "\n", root / ("docs/" + stem + ".html"): page})
for path, content in outputs.items():
    if args.check:
        if not path.is_file() or path.read_text() != content:
            raise SystemExit("Public privacy copy is out of date. Run python3 scripts/render-privacy.py")
    else:
        path.write_text(content)
print("PASS: public privacy and terms copies match the bundled documents" if args.check else "Updated public privacy and terms copies")
