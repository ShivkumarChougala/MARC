# Privacy release review

This is a source review, not a completed App Store privacy submission.

## App manifest

`MARC/PrivacyInfo.xcprivacy` declares:

| Category | Reason | App use |
| --- | --- | --- |
| User defaults | CA92.1 | App-owned preferences, saved profile metadata and history settings |
| System boot time | 35F9.1 | Local elapsed-time measurements for collector health and refresh cadence |

The manifest declares no tracking. It does not assert that every possible
user-configured AI service collects no data. Collected-data declarations and
App Store Connect answers must be finalized alongside the actual release's
privacy policy and optional provider behavior.

Mac disk usage, remote file timestamps and remote uptime are read by scripts
on the Mac. They are distinct from iPhone required-reason APIs. The local
upload metadata read requests regular-file status and size, not timestamps.

## Before distribution

- Run `bash scripts/verify-marc.sh`; it checks manifest inclusion in the built app.
- Create a Release archive and inspect Xcode's privacy report, including all
  linked Swift packages. The app manifest does not replace dependency manifests.
- Confirm provider retention and use before answering App Store data-collection
  questions. API mode sends the user's prompt to their chosen endpoint.
- Publish a privacy policy that explains local storage, SSH connections,
  optional AI transmission, file sharing and deletion boundaries.
- Confirm usage descriptions and permissions in the archived Info.plist.
- Complete export-compliance questions for the actual SSH/cryptography build.

No paid developer membership is needed to review source or run local simulator
checks. Distribution is a separate release step.

References: Apple's “Describing use of required reason API” and TN3183,
“Adding required reason API entries to your privacy manifest”. Re-check their
current reason definitions when preparing the release.
