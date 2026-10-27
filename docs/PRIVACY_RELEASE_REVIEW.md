# Privacy release review — 27 October 2026

Supersedes the 22 October implementation checklist. See
[the current data-handling audit](DATA_HANDLING_AUDIT.md),
[validation results](POLICY_AUDIT_VALIDATION.md) and
[policy publishing workflow](PRIVACY_PUBLISHING.md).

The new Privacy Policy and Terms remain review drafts pending the operator's
business decisions listed in the audit. The website and offline canonical
content are synchronized without a website redesign. Third-party license
files now exist and the license checker passes; the historical statement that
this ZIP lacks LICENSE/notices is no longer current.

Before publishing or shipping:

- Confirm operator/contact identity, support mail provider and retention,
  target markets/ages, hosting practices and current distribution terms.
- Confirm the effective/publication date and re-render all copies.
- Run the existing full verifier on macOS and verify the exact resources in
  the signed build. Read both Legal screens without a network on iPhone.
- Review the actual release archive, dependency privacy report, App Store
  privacy answers, encryption/export questions and review instructions.
- Publish the synchronized website and app resources through the normal
  review process. No deployment or GitHub push occurred in this audit.
