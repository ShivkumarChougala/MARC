# Changelog

## Unreleased

### Buffered SSH commands and interface improvements

- Enforce output budgets before queueing buffered command data; reject
  queue overflow and close command channels on cancellation or completion.
- Add 15 native command-output regression tests and update provenance
  and matching open-source notices.
- Move Status customization into the navigation bar and replace the
  accent menu with a colour-selection sheet.
- Simplify first-connection trust approval with optional advanced
  fingerprint comparison; retain saved-key and changed-key checks.
- Let the Processes heading and column labels scroll away while search
  and sorting rise into a pinned header without a blur panel.


### SSH private-key import hardening

- Validate cipher and key-derivation combinations, AES key/IV lengths and
  private-key framing before decryption.
- Check every padding byte and accept full-block padding emitted by the encoder.
- Add malformed-input and valid encrypted-key regressions; update local source
  provenance and matching offline notices.

### Transfer privacy declaration

- Declare disk-space access used to check available storage before and during
  local transfers.
- Require the declaration in privacy verification and verify that the built
  app includes the current manifest.

### Cryptography dependency update

- Update Swift Crypto to 5.0.3, including upstream RSA public-key parsing and
  VOPRF input-length fixes.
- Add regression coverage for malformed RSA keys, valid signatures and VOPRF
  input boundaries alongside the existing SSH signature tests.
- Refresh dependency provenance and offline notices, including XKCP notices.

### SSH parser hardening and terminal feedback

- Reject oversized ECDSA signature integers before copying signature data.
  Use reviewed local Citadel and SSH snapshots with matching source provenance
  and open-source notices.
- Add malformed-signature and valid-signature regression coverage for all three
  supported ECDSA curves.
- Keep host-trust cancellation independent of main-actor scheduling and verify
  trust-flow behaviour with the app's actor-isolation settings.
- Show a dismissible alert when the terminal clipboard contains no text.

### 2026-10-22 — Security and resilience improvements

Changes included in [e180c78](https://github.com/ShivkumarChougala/MARC/commit/e180c78786783da3aa3eea7d427a20408fdde4f7).

#### Security

- Require SSH host fingerprint approval before authenticating a new connection.
  Preserve existing pins and block changed host keys, with checks for cancelled
  or stale approvals and trust-storage failures.
- Use private staging permissions for uploads and remote edits. Preserve
  destination permissions, ACLs, extended attributes and quarantine provenance
  when replacing files; reject replacement when required metadata cannot be
  preserved.
- Protect temporary downloads and imported media with private permissions and
  iOS file protection. Retain files while previews or transfers need them,
  exclude temporary directories from backup, and clean recognized abandoned
  directories without following candidate symlinks.
- Reject AI command suggestions containing hidden formatting, control
  characters, embedded line breaks or oversized text. Invalidate suggestions
  when the connection, configuration or prompt changes, or the view is left
  or backgrounded.

#### Reliability and usability

- Limit concurrent terminal sessions to four. Show an on-demand limit dialog
  when an additional session is requested, with the session count in the picker.
- Bound directory listings to 5,000 entries and 2 MiB of metadata, previews to
  50 MiB, and downloads to 512 MiB. Check available storage before and during
  local transfers.
- Bound folder archives by input size, output size, item count, depth and time.
  Add stalled-transfer recovery, cancellation fallback and Reconnect Files.
- Keep AI suggestions in a compact command row with Run and dismiss actions.
  Generating a suggestion never executes it; a deliberate Run tap clears the
  suggestion before sending the command followed by one Return.

#### Legal resources and verification

- Add offline Privacy Policy and Terms of Use screens under Settings, with
  links to the published policies and generated reference documents.
- Add offline open-source notices for all 14 pinned dependencies and verify
  notice integrity, pinned revisions and inclusion in the built app. Preserve
  original bundled notice text while normalizing Markdown whitespace.
- Expand regression checks for host trust, uploads, temporary files, AI
  command validation, resource budgets and built-app resources.

#### Operational notes

- AI text validation does not determine whether a command is safe or whether
  the terminal is at an empty shell prompt. Review commands before running them.
- After a forced transfer disconnection, remote completion or temporary-file
  cleanup may be uncertain. Check the remote result before retrying an action.
