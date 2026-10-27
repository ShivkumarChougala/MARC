# Policy audit validation — 27 October 2026

## Passed in this environment

- `python3 scripts/render-privacy.py --website-root <website>` regenerated the
  app reference copies and existing website content without changing its shell.
- `python3 scripts/verify-privacy.py --website-root <website>` passed manifest,
  document schema, offline Settings route, generated-copy and website synchronization checks.
- `python3 Tests/PolicyPublishingChecks.py <website>` passed repeat application,
  HTML escaping, canonical-change invalidation, and independent website drift checks.
- Website `build.py` and `check.py`: **21 pages, 607 local references**, valid
  anchors, current documentation search index, no unreferenced assets and correct fingerprints.
- `scripts/verify-licenses.py`: 14 packages (12 remote, 2 local), exact notices.
- `scripts/verify-source-hygiene.py`: app sources/assets resolve; no transient artifacts.
- `Tests/HostTrustChecks.py --source-only`: visible trust-sheet integration,
  request ownership and fail-closed validator wiring. Native tests were not run.
- `Tests/DeveloperToolsChecks.py --source-only`: production Python handler
  parsing, limits, action safeguards, target/state guards, failures and cleanup;
  source check for observable cache. Native Swift fixture was not run.
- Existing `scripts/verify-marc.sh` passed SSH snapshot/provenance/pin checks,
  17 production remote-handler resource-budget checks and source hygiene before
  stopping at its explicit Xcode prerequisite.
- Byte comparison: all website CSS, JavaScript, components and assets unchanged
  from the previous prepared website base; all app Swift source files unchanged
  from the current uploaded ZIP. Policy and documentation content changed.

## Not verified here

No Swift compiler or Xcode is installed. The full Mac verifier **did not pass**:
its remaining Swift runtime, iOS build, signed-bundle and device stages did not run.
No claim of iPhone offline execution, archive-resource inclusion or App Store
privacy/export compliance is made. Follow `PRIVACY_PUBLISHING.md` on the Mac.

The live website's Cloudflare beacon was observed in browser DOM. Hosting account
settings, logs/exports, retention, support mailbox, provider accounts and legal
business identity were not accessible from the source. No packet capture or
forensic data-deletion verification was performed.
