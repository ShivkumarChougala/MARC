# Privacy release review — 22 October 2026

This review covers the supplied source and the public getmarc.app pages.
It is not a completed App Store submission or a legal compliance certification.

## Current implementation

- Settings → Legal always remains visible and opens offline Privacy and Terms.
- Each document offers an explicit link to the current published version.
- App website links use getmarc.app; legal contacts use contact@getmarc.app.
- The bundled documents follow the published 22 October 2026 text. The prepared
  privacy document additionally discloses the observed Cloudflare analytics
  beacon. The website still needs that sentence; see FIX_03_REVIEW.md.
- API prompt and model-catalogue sharing use separate destination approvals.
- AI starts Off. Credentials/API keys use Keychain. SSH and API mode use SSH
  and HTTPS respectively. Custom providers determine their own data handling.
- Temporary downloads, the remote history database and deletion limitations
  are disclosed. Profile removal does not erase remote history or provider data.
- The published 90-day resolved support correspondence commitment remains an
  operational practice; the app does not configure mailbox deletion.

## Existing required-reason declarations

| API category | Reason | Source usage |
| --- | --- | --- |
| User defaults | CA92.1 | App-owned settings and saved profile metadata |
| System boot time | 35F9.1 | Elapsed-time measurements for health and cadence |

The app manifest remains unchanged. It declares no tracking. The source checks
are not a substitute for Xcode's archive privacy report or dependency review.

## Release work still required

- Run the Mac verifier and test both Legal screens on iPhone without a network.
- Apply the website analytics sentence and keep both policies consistent.
- Ensure contact@getmarc.app receives support/privacy requests.
- Complete licensing and third-party notices: the supplied ZIP lacks LICENSE
  and dependency notice files despite the website referring to them. Confirm
  the current public repository as part of the next licensing review.
- Review the Release archive's dependencies and privacy report.
- Finalize App Store privacy answers for optional AI and support processing;
  do not infer “Data Not Collected” solely from the absence of a MARC server.
- Complete export-compliance answers for the actual cryptography build.
- Prepare a usable App Review environment and instructions for SSH features.

Official references checked during this work:
- https://developer.apple.com/app-store/review/guidelines/#privacy
- https://developer.apple.com/app-store/app-privacy-details/
- https://developers.cloudflare.com/web-analytics/about/
- https://developers.cloudflare.com/web-analytics/data-metrics/data-origin-and-collection/
