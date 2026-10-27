"""Exercise legal publishing against isolated copies; never use a network or real device."""
from pathlib import Path
import json
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
website = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else root / 'web'
with tempfile.TemporaryDirectory(prefix='marc-policy-publishing-') as folder:
    app = Path(folder) / 'app'
    web = Path(folder) / 'web'
    for path in ('scripts', 'MARC/Resources', 'docs'):
        (app / path).mkdir(parents=True)
    web.mkdir()
    for name in ('render-privacy.py', 'policy_website.py'):
        shutil.copy2(root / 'scripts' / name, app / 'scripts' / name)
    for name in ('MARCPrivacyPolicy', 'MARCTermsOfUse'):
        shutil.copy2(root / 'MARC/Resources' / (name + '.json'), app / 'MARC/Resources' / (name + '.json'))
    for name in ('privacy.html', 'terms.html'):
        shutil.copy2(website / name, web / name)
    command = [sys.executable, str(app / 'scripts/render-privacy.py'), '--website-root', str(web)]
    subprocess.run(command, check=True, capture_output=True)
    snapshots = {p: p.read_bytes() for p in (*web.glob('*.html'), *app.joinpath('docs').glob('*'))}
    subprocess.run(command + ['--check'], check=True, capture_output=True)
    subprocess.run(command, check=True, capture_output=True)
    assert all(p.read_bytes() == data for p, data in snapshots.items()), 'Publishing must be repeatable'
    # Changing a canonical paragraph must invalidate both independently shipped copies.
    p = app / 'MARC/Resources/MARCPrivacyPolicy.json'
    document = json.loads(p.read_text())
    document['sections'][0]['paragraphs'].append('Publishing regression: <private> & "quoted".')
    p.write_text(json.dumps(document))
    assert subprocess.run(command + ['--check'], capture_output=True).returncode != 0
    subprocess.run(command, check=True, capture_output=True)
    assert '&lt;private&gt; &amp; &quot;quoted&quot;' in (web / 'privacy.html').read_text()
    subprocess.run(command + ['--check'], check=True, capture_output=True)
    # Website-only drift must fail even when the generated offline documents are current.
    p = web / 'privacy.html'
    p.write_text(p.read_text().replace('Publishing regression:', 'Undocumented edit:'))
    assert subprocess.run(command + ['--check'], capture_output=True).returncode != 0
print('PASS: repeatable publishing, escaped content, canonical changes and independent website drift detection')
