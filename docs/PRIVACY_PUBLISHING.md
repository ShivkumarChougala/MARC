# MARC policy publishing

The public pages are https://getmarc.app/privacy and https://getmarc.app/terms.
Both returned HTTP 200 during this review on 22 October 2026. The website has
its own layout and publishing workflow; this installer does not change it.

Settings → Legal now displays bundled Privacy Policy and Terms of Use screens.
They do not load a website to display the documents. External references,
email and “Read on getmarc.app” links open only when selected.

Sources:
- MARC/Resources/MARCPrivacyPolicy.json
- MARC/Resources/MARCTermsOfUse.json

These are based on the published 22 October 2026 policies. The prepared privacy
copy adds one Cloudflare Web Analytics disclosure; apply that sentence to the
existing website's section 8 as explained in FIX_03_REVIEW.md. Do not replace
the website with the plain generated HTML just to make this change.

After an intentional policy edit:

```bash
python3 scripts/render-privacy.py
python3 scripts/verify-privacy.py
bash scripts/verify-marc.sh
```

The renderer generates docs/PRIVACY.md, docs/privacy.html, docs/TERMS.md and
docs/terms.html. These are reference copies, not automatic website deployment.
The verifier checks their consistency and the exact bytes of both JSON
resources in the built app. Keep website and bundled policy changes together
for each release. A later website update does not alter an installed app.

Use https://getmarc.app/privacy as the App Store Connect privacy policy URL.
Check it without signing in before submission. Keep the contact@getmarc.app
mailbox working and apply the published support-record retention practice.
