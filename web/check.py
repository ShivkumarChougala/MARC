"""Validate the built static site using only Python's standard library."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent
DIST = ROOT / 'dist'

class Page(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.ids = set()
        self.refs = []
        self.scripts = []
        self.components = False
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if attrs.get('id'):
            assert attrs['id'] not in self.ids, f"Duplicate ID: {attrs['id']}"
            self.ids.add(attrs['id'])
        self.components |= 'data-component' in attrs
        if tag == 'script' and attrs.get('src'):
            self.scripts.append(attrs['src'])
        for key in ('src', 'href'):
            if attrs.get(key):
                self.refs.append(attrs[key])
        if attrs.get('srcset'):
            self.refs.extend(item.strip().split()[0] for item in attrs['srcset'].split(','))


def resolve(page, path):
    target = DIST / unquote(path.lstrip('/')) if path.startswith('/') else page.parent / unquote(path)
    if not path:
        return page
    if target.is_dir():
        return target / 'index.html'
    if not target.suffix and target.with_suffix('.html').is_file():
        return target.with_suffix('.html')
    return target


def main():
    pages = sorted(DIST.rglob('*.html'))
    assert pages, 'Run python3 build.py first.'
    parsed = {p: Page(p.read_text(encoding='utf-8')) for p in pages}
    refs = 0
    for page, doc in parsed.items():
        assert not doc.components, f'Unresolved component in {page}'
        assert len(doc.scripts) == len(set(doc.scripts)), f'Duplicate script in {page}'
        for value in doc.refs:
            url = urlsplit(value)
            if url.scheme or url.netloc:
                continue
            target = resolve(page, url.path).resolve()
            assert target.is_relative_to(DIST.resolve()), f'Path escapes output: {value}'
            assert target.is_file(), f'{page.name}: missing {value}'
            if url.fragment and target.suffix == '.html':
                target_doc = parsed.get(target)
                if target_doc is None:
                    target_doc = Page(target.read_text(encoding='utf-8'))
                assert unquote(url.fragment) in target_doc.ids, f'{page.name}: missing anchor {value}'
            if url.query.startswith('v='):
                expected = hashlib.sha256(target.read_bytes()).hexdigest()[:12]
                assert url.query == 'v=' + expected, f'Stale asset version in {page.name}: {value}'
            refs += 1
        text = page.read_text(encoding='utf-8')
        match = re.search(r'<script[^>]*id="docs-index"[^>]*>(.*?)</script>', text, re.S)
        if match:
            index = json.loads(match.group(1))
            assert len(index) == 13, f'Unexpected documentation index in {page.name}'
            for guide in index:
                assert resolve(page, urlsplit(guide['url']).path).is_file(), f'Missing indexed guide: {guide["url"]}'
    for path in (DIST / 'css').glob('*.css'):
        for value in re.findall(r'url\([\'\"]?([^\'\")]+)', path.read_text()):
            url = urlsplit(value)
            if not url.scheme and not url.netloc:
                assert resolve(path, url.path).is_file(), f'Missing CSS asset: {value}'
    for path in (DIST / 'js').glob('*.js'):
        for value in re.findall(r'[\'\"](/?assets/[^\'\"]+)', path.read_text()):
            assert (DIST / urlsplit(value).path.lstrip('/')).is_file(), f'Missing JS asset: {value}'
    print(f'PASS: {len(pages)} pages, {refs} local references, documentation index and asset fingerprints.')

if __name__ == '__main__':
    main()
