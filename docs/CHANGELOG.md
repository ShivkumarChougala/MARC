# Changelog

## Unreleased

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
