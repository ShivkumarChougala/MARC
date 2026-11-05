# How MARC works — source review and validation

Reviewed 5 November 2026. Implementation reference: `7895145badb2c308fb8eabe4ac5d8ae275d3cfd3` from public `origin/main` (Compact service states and prepare Settings and keyboard for release).

## Delivered website changes

- New `web/docs/how-marc-works.html`: approachable overview, connection/channel distinction, collectors and Python, expandable five-column command references, interpretation, Activity Monitor, retention/cleanup, lifecycle, network/AI and tradeoffs.
- Existing documentation shell, typography, navigation, search dialog and footer retained. Added scoped table styling with keyboard-focusable horizontal scrolling.
- Navigation in every guide, context links in setup/introduction, monitoring, processes, Files, Terminal, controls, Services, AI, troubleshooting and security; adjacent-guide links updated.
- Corrected Settings' refresh explanation: publishing cadence is not the monitoring loop's sleep interval.
- Sitemap updated. `web/update-docs-index.py` generates all 14 embedded indexes from current article text, including closed details. Build rejects stale search text. Website checker verifies complete index membership, identical indexes, navigation, sitemap inclusion, references/anchors and resource fingerprints.
- No app implementation, legal policy, homepage, marketing section or asset changed. No commit, push or deployment performed.

## Evidence map

All paths below are relative to the reviewed repository. Function names and embedded script markers identify the evidence without relying on moving line numbers.

| Claims | Evidence inspected |
| --- | --- |
| Probe before login, endpoint-scoped trust, changed-key blocking | `MARC/Services/SSHHostKeyProbe.swift` (`ProbeNoAuthentication`, `fetch`), `MARCHostTrust.swift` (`keyForConnection`, store), `SSHConnectionTest.swift` (`hostKeyValidator`), `HostKeyIdentity.swift` |
| Password or local Ed25519 signing; no private-key upload in normal authentication | `MARC/Services/MARCLogin.swift` (`key`, `authentication`); caller settings in monitoring, Files and Terminal |
| Main monitoring connection, stdout JSON decoding, publication cadence, liveness | `MARC/Services/SSHMonitor.swift` (`connect`, `publish`, `collectorCommand`, `finishCollector`, `resetConnection`), `MARCCollectorHealth.swift` |
| Real SSH command channels versus PTY/shell and SFTP channels | `Vendor/Citadel/Sources/Citadel/TTY/Client/TTY.swift` (`_executeCommandStream`, `withPTY`); `Vendor/Citadel/Sources/Citadel/SFTP/Client/SFTPClient.swift` (`openSFTP`) |
| CPU, per-core ticks, memory estimate, storage and disk/network counters, power | `SSHMonitor.swift`, embedded monitoring script, `MARC_DISK_COUNTERS`, `MARC_NETWORK_COUNTERS`, `MARC_STORAGE_CAPACITY`, `MARC_BATTERY_HEALTH` markers; `MacSnapshot.diskCapacityUsed` |
| No cached/compressed breakdown in current payload | Monitoring script's `sample`/`details` and Swift `MacSnapshot`/`SystemDetails` decoding fields; `MARC/Screens/LiveSystemDetailScreen.swift` |
| Process stream, RSS, CPU deltas and stop marker | `SSHMonitor.swift` (`processUpdates`, `stopProcessStream`, `terminateProcess`); `MARC/Screens/HomeScreen.swift` (`refreshProcesses`) and `ProcessesScreen.swift` |
| SQLite fields, five-second writes, active-only pruning, legacy table retention, archive buckets | `SSHMonitor.swift` (`MARCHistoryWriter`, `loadArchivedHistory`); `MARCStatisticsData.swift` and `MARC/Screens/MARCStatisticsScreen.swift` |
| Separate Files transport, SFTP bytes/rename and Python metadata | `MARC/Services/MARCRemoteFiles.swift` (`connect`, `listing`, `upload`, `download`, `perform`, `stop`), `MARCFileOperations.swift` (`MARCFileBridge`, `execute`) |
| Metadata inspection may read eligible text locally; staging/replacement/archive mechanics | `MARCFileOperations.swift` (`editor_support`, `private_stage`, `preserve_metadata`, `archive`), `MARCRemoteFiles.swift` transfer/error paths |
| Protected iPhone temporary files, leases, startup sweep and export limits | `MARC/Services/MARCLocalDownload.swift` (`MARCTemporaryFileStore`, `MARCTemporaryFile.deinit`); `MARC/Screens/FilesScreen.swift` |
| Each Terminal opens its own SSH connection, PTY shell, max four, in-memory buffers | `MARC/Screens/MARCTerminalScreen.swift` (`MARCTerminalSession.run`, `stop`, `MARCTerminalWorkspace`, `pause`, `localAI`) |
| Control queries versus changes, macOS APIs, optional tools, installed apps and media fields | `MARC/Services/MARCControlScript.swift` (`MacAudio`, `MacBrightness`, read/action dispatch, catalog, lock, media); `MARC/Screens/ControlsScreen.swift` refresh loop |
| Listening ports, protected process stops, Homebrew run/stop, Docker local socket and state checks | `MARC/Services/MARCDeveloperTools.swift` embedded Python (`services`, `stop_listener`, `managed_services`, `docker`); `SSHMonitor.marcDeveloperRequest`; `MARCDeveloperToolsView.swift` refresh task |
| Local/API AI destinations, actual request fields, consent, no automatic context attachment | `MARC/Screens/MARCTerminalAI.swift` (`generate`, consent logic), Terminal `localAI`, `SSHMonitor.marcInstalledAIModels`, `MARC/Services/MARCAPIProvider.swift`, `MARCAIResponseReader.swift` |
| Backgrounding and reconnection ownership | `MARC/ContentView.swift` scene-phase handling/reconnect task, monitor cancellation/closure, Files stop paths, Terminal workspace pause |
| Local credential/preferences removal | `MARC/Services/MARCHostTrust.swift`, `MARCSSHKeyStore.swift`, `MARCAPIKeyStore.swift`, `MARCCredentials` and `ServerStore` in `MARC/Models/` |
| No built-in relay or installer for collector persistence | Built-in SSH/URLSession destinations and embedded-script dispatch; searched production app for launch/scheduled-job/script-write paths, then inspected actual write sites. Optional user-run install commands and Homebrew-managed services explicitly excluded from this absence claim. |

## Published documentation and privacy comparison

The live documentation entry page's readable text matched the fetched repository before changes. Live Privacy was retrieved directly over HTTPS because the web retrieval service could not open it. Direct requests for the individual live guide routes were unavailable through the later Python retrieval path, so their before/after content comparison uses the fetched main-branch source; this is not a claim of independently rechecking every deployed guide. The published policy's substantive paragraphs on SSH identity, data categories, history, files, local storage, services and AI agree with the new guide. Cloudflare expands website navigation/footer and obfuscates email display; these are delivery differences, not privacy contradictions.

**Pre-existing publication drift requires follow-up.** `python3 scripts/render-privacy.py --check` passes for the bundled/canonical public copies under `docs/`. `python3 scripts/verify-privacy.py --website-root web` fails because the designed website legal pages differ from the canonical JSON render. This was not caused by the documentation patch; no legal file was edited.

Differing Privacy section IDs: `overview`, `storage`, `files-history`, `ai`, `support`. Differing Terms section IDs: `setup`, `ai`. Inspected Privacy differences include operator/support phrasing, preference and temporary-file explanations, and the website explicitly limiting AI to Terminal. Hostinger is disclosed in both the checked website and canonical support paragraphs. These render differences should be reconciled deliberately; blindly regenerating would overwrite previously approved website wording. The new guide does not require a new legal or business decision. It does not resolve audience/age decisions or certify App Store compliance.

## Validation

- PASS: installer tested against a clean copy of the reviewed website, repeated application, and refusal of conflicting local edits without changing any website bytes.
- PASS: source search-index generation and check; website build (22 pages); website checker (675 local references, anchors, complete 14-guide indexes, navigation, sitemap and fingerprints); `node --check web/js/docs.js`; `git diff --check`; `scripts/verify-source-hygiene.py`.
- PASS: browser desktop opening layout, existing shell/navigation, expanded monitoring command reference and rendered angle-bracket arguments. Search for `history.sqlite` returns the new guide; mobile search for `host_processor_info` returns it and its result navigates to the new heading.
- PASS: browser iframe viewport checks at 320, 390 and 768 px, using real documents/CSS. No document horizontal overflow. At 320 px an open table has a 269 px scroll container and 940 px content, so the table scrolls independently. Mobile browse menu opens. This is responsive browser QA, not a physical iPhone Safari test.
- PASS: `Tests/DiskCollectorChecks.py`, `NetworkCollectorChecks.py`, `StorageCollectorChecks.py`, `FileActionChecks.py` (63 checks), `PolicyPublishingChecks.py` (isolated publishing regression).
- PARTIAL: `ProcessChecks.py` and `DeveloperToolsChecks.py` passed their Python/mocked behavior checks, then stopped at Swift-dependent checks.
- NOT RUN TO COMPLETION: native Swift checks in `ConnectionLifecycleChecks.py`, `TerminalFilesTaskChecks.py`, `AIRequestChecks.py`, plus the native portions above; this Linux environment has no Swift/Xcode. No live Mac SSH, physical-device lifecycle/permission test, or resource-overhead benchmark was performed. Runtime cleanup timing remains explicitly qualified.
- EXPECTED EXISTING FAILURE: `scripts/verify-privacy.py --website-root web` as described above. The isolated publishing regression passing does not mean the current website legal copies match.

## Scope limits

This audit uses the latest public source available at the start of the task, not unpublished edits in `~/projects/MARC-current`. Provider retention, account policies, local Ollama configuration, macOS tool/framework availability and user programs are outside the built-in implementation; the page states those limits instead of inventing guarantees. Separate cached/compressed memory display fields were not present at the reviewed revision. Recheck if later app work adds them.

## Apply locally

The accompanying installer changes only its enumerated website files. It validates the entire candidate site before copying, checks payload hashes and reviewed baselines, backs up affected files, validates again, and restores affected files on failure. Conflicting local edits stop it before copying. It does not copy app files, generate legal policies, commit, push or deploy. Review locally before a separately authorized direct push to main.

## Copy and spacing refinement

Reviewed all 14 guides for tone and duplication. Shortened How MARC works by about 13% while preserving its command tables and essential qualifications. Removed the implementation-audit note from the public article; the source revision remains in this report. Related reading is now a short paragraph instead of a separate heading and contents entry. Introduction, Monitoring, AI and Security start with their purpose/task before secondary details. Existing named anchors are preserved.

How MARC works uses 32 px section spacing on desktop and 28 px on narrow layouts, with consistent disclosure spacing. Five-column command tables have a 940 px minimum width to keep the columns readable and scroll within their panel; the two-column connection table uses 520 px. Search indexes were regenerated. No new app behavior is claimed and legal pages are unchanged.

The revised installer accepts both the original reviewed website and the previously delivered documentation update. Other local edits still stop it before copying.

## Direct documentation wording

Removed editorial descriptions such as “plain-English explanation” and “the sections below explain each action.” Related links now name their subject directly. Introduction and new-page metadata describe the product/topic without describing the writing style. Regenerated all search indexes; build and 675-reference checks pass. No technical or legal behavior changed.
