# Policy publishing and review

The canonical policy content is:

- `MARC/Resources/MARCPrivacyPolicy.json`
- `MARC/Resources/MARCTermsOfUse.json`

The 27 October 2026 drafts require the business decisions in
`DATA_HANDLING_AUDIT.md` before publication. The date is provisional until approved.
Do not treat a successful source check as legal approval or an App Store declaration.

Settings → Legal reads the bundled JSON offline. The app's summary remains a
non-exhaustive guide; the document introduction, sections and references are canonical.
Installed apps retain their bundled version until a new build is installed.

## Render and verify

For separate local app and website folders:

```bash
cd "$HOME/projects/MARC-current"
python3 scripts/render-privacy.py --website-root "$HOME/projects/marc-public"
python3 scripts/verify-privacy.py --website-root "$HOME/projects/marc-public"
python3 Tests/PolicyPublishingChecks.py "$HOME/projects/marc-public"
python3 "$HOME/projects/marc-public/build.py"
python3 "$HOME/projects/marc-public/check.py"
```

The renderer regenerates `docs/PRIVACY.md`, `docs/TERMS.md`, `docs/privacy.html`
and `docs/terms.html`. `--website-root` additionally replaces content inside the
existing website Privacy/Terms shell. It preserves CSS, navigation components,
metadata, layout classes and footer. Do not deploy the plain reference HTML in
place of the designed website pages.

`--check` performs no writes. `verify-privacy.py` retains its existing optional
built-app positional argument and now accepts `--website-root` too:

```bash
python3 scripts/verify-privacy.py /path/to/MARC.app --website-root /path/to/website
bash scripts/verify-marc.sh
```

The built-app check compares the exact JSON and privacy-manifest bytes in the
bundle. The full verifier requires Xcode on macOS. Test both Legal documents in
Airplane Mode on iPhone, including scrolling and explicitly opened external links.

Before release, confirm the operator/contact details, support retention and mail
provider, live Cloudflare configuration, intended markets and ages, and purchase
terms. Update the provisional date on approval and rerun the renderer and checks.
Review App Store privacy answers and the archive privacy report separately. An
absence of a MARC relay does not establish that no data is collected by providers.

Publish the website copies and ship the corresponding app resources together.
This workflow prepares content; it does not upload, commit or deploy it.
