"""Rebuild every embedded documentation search index from the source articles."""
from html.parser import HTMLParser
from pathlib import Path
import argparse
import json
import re

ROOT = Path(__file__).resolve().parent
INDEX = re.compile(r'(<script\b[^>]*id="docs-index"[^>]*>)(.*?)(</script>)', re.S)


class Article(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.depth = 0
        self.title_depth = 0
        self.title = []
        self.words = []
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'h1':
            self.title_depth += 1
        if tag == 'div' and 'article-body' in attrs.get('class', '').split():
            self.depth = 1
        elif self.depth and tag == 'div':
            self.depth += 1

    def handle_endtag(self, tag):
        if tag == 'h1':
            self.title_depth = 0
        if tag == 'div' and self.depth:
            self.depth -= 1

    def handle_data(self, text):
        if self.title_depth:
            self.title.append(text)
        if self.depth:
            self.words.append(text)


def sources():
    return [ROOT / 'docs.html', *sorted((ROOT / 'docs').glob('*.html'))]


def make_index():
    guides = []
    for page in sources():
        article = Article(page.read_text(encoding='utf-8'))
        title = ' '.join(' '.join(article.title).split())
        text = ' '.join(' '.join(article.words).split())
        if not title or not text:
            raise SystemExit('Missing documentation article: ' + str(page))
        guides.append(dict(title=title, url='/' + page.relative_to(ROOT).as_posix(), text=text))
    return guides


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    index = make_index()
    encoded = json.dumps(index, ensure_ascii=False).replace('<', '\\u003c')
    for page in sources():
        text = page.read_text(encoding='utf-8')
        match = INDEX.search(text)
        if not match:
            raise SystemExit('Missing search index: ' + str(page))
        if args.check:
            if json.loads(match[2]) != index:
                raise SystemExit('Stale docs search index. Run python3 update-docs-index.py')
        else:
            page.write_text(INDEX.sub(lambda m: m[1] + encoded + m[3], text), encoding='utf-8')
    print(f'PASS: {len(index)} documentation guides in every search index.')


if __name__ == '__main__':
    main()
