# MARC data-handling audit — 27 October 2026

**Review draft. Not published, not a legal compliance certification.**

## Scope and result

Input archive SHA256: `8ed505576f1305c88877952613e195527659fc55bd028ae418eb3d56a109f6e1`.

Reviewed the supplied `MARC-current(9).zip` app source, the current website
source prepared in this conversation, and the live site's analytics script.
The ZIP source is authoritative for app behavior. The website base includes the
previously prepared Services & Docker guide and screenshot update; it is not a
fresh download of the user's local website. Reconcile any subsequent local edits
before installation. No app behavior, website CSS, navigation or layout was changed.

The new Privacy and Terms introductions describe MARC professionally. Legal
operator identity remains in the responsibility/contact section, rather than a
personal first-person opening. The current source identifies Shivkumar Chougala;
confirm the operating legal person before publication.

The website Privacy content was older than the bundled JSON and omitted the
Cloudflare analytics disclosure. Both policies and all generated reference copies
now share canonical content. Existing policy paragraph IDs that changed have been
updated in documentation links and tables of contents. Offline JSON is not remotely
updated when the website changes.

## Verified information flows

Paths below are relative to the app repository. Function and field names identify
the evidence, so they remain useful when line numbers change.

| Feature / information | Recipient or storage | Trigger / lifetime | Source evidence |
| --- | --- | --- | --- |
| Bonjour SSH service names, host addresses and ports | Local network discovery; iPhone discovery state | Nearby scan; DNS/local name resolution depends on network | `MARC/Services/BonjourDiscoveryService.swift`; `Config/MARC-Info.plist` `_ssh._tcp` |
| Host public key and SHA256 identity | iPhone Keychain, endpoint-scoped by host + port | New identity approval before authentication; later changes fail closed | `MARC/Services/MARCHostTrust.swift` `keyForConnection`, `remember`; `HostKeyIdentity.swift`; `SSHConnectionTest.swift` validator |
| Password login | Selected Mac over encrypted SSH; saved login in Keychain | User connection; saved until removed | `Models/ServerStore.swift` `MARCCredentials`; `Services/MARCLogin.swift` passwordBased |
| SSH private key and passphrase | iPhone Keychain and authentication memory | Import/save; local signing for Ed25519; no normal private-key upload | `Services/MARCSSHKeyStore.swift`; `MARCLogin.swift` `key` / `authentication` |
| API secrets / destination binding | iPhone Keychain; selected provider in an auth header | Explicit prompt/catalogue requests; deleting locally is not provider revocation | `Services/MARCAPIKeyStore.swift`; `MARCAPIProvider.swift`; `Screens/MARCTerminalAI.swift` |
| Profiles, model/endpoint choices, UI preferences, last folder, Quick Launch | iPhone UserDefaults / app preferences | Saved settings; per-profile cleanup on removal | `Models/ServerProfile.swift`; `Models/ServerStore.swift` `removePreferences`; `@AppStorage` call sites |
| Monitoring payload | Mac → iPhone over SSH; Mac `~/.local/share/marc/history.sqlite` | Save at most roughly every 5 s; active pruning of own rows older than 7200 s | `Services/SSHMonitor.swift` collector `MARCHistoryWriter.save`, sample construction |
| History identifiers | Same remote database | Includes hostname, username, local IP, OS/hardware/interface, uptime/power where available, not just activity percentages | `SSHMonitor.swift` `details` and `sample` dictionaries |
| Terminal input/output | Selected Mac over SSH; current app terminal state in memory | User input and remote output; remote shell/apps can retain history/logs | `Screens/MARCTerminalScreen.swift` session send and output paths |
| Local AI generation | Selected Mac via SSH → `127.0.0.1:11434/api/chat` | User generation; local runtime behavior/logs outside client control | `MARCTerminalScreen.swift` `localAI`; `SSHMonitor.swift` `/api/tags` model discovery |
| API generation | OpenAI / Google Gemini / Groq / custom endpoint operator | Prompt + model + fixed system instruction; selected API key; IP/request metadata | `MARCTerminalAI.swift` `generate`; `MARCAPIProvider.swift` endpoints |
| API approval | Session-only UI state; separate catalogue permission | Endpoint approved for current Terminal session, not every prompt; configuration/connection resets; catalogue approval independent | `MARCTerminalAI.swift` `approvedAPIEndpoint`, `approveAPIRequest`, alerts and onChange handlers |
| API transport | Approved HTTPS endpoint | Ephemeral URLSession, no cookies/persistent URL cache, redirects refused | `Services/MARCAIResponseReader.swift` `MARCAINoRedirect.session` |
| File browsing and metadata | Mac → iPhone over SSH | User browsing/details operations | `Services/MARCRemoteFiles.swift`; `MARCFileOperations.swift` |
| Upload/download/preview/edit | Selected Mac over SFTP/SSH; selected picker or share destination | App temp copies; remote staging and folder archives; best-effort cleanup | `MARCRemoteFiles.swift`; `Screens/FilesScreen.swift`; `MARCFileOperations.swift` |
| App-created temporary files | iPhone protected app temp directories | Complete Protection before payload, private modes, backup exclusion, lease cleanup + recognized startup sweep | `Services/MARCLocalDownload.swift` `makeFile`, `attributes`, `ensurePrivateDirectory`, `sweep`, lease deinit |
| Services / ports / Docker results | Mac → iPhone; connection-bound memory cache | Active reads; only selected actions; selected tab in preferences | `Services/MARCDeveloperTools.swift`; `MARCDeveloperToolsView.swift`; `SSHMonitor.swift` developer cache |
| Controls and media metadata | Selected Mac → iPhone over SSH | Supported readings include displays/audio, Wi-Fi/Bluetooth state, installed app names/IDs and Now Playing title/artist/source | `Services/MARCControlScript.swift` result / installed_apps / read_now_playing |
| Explicit clipboard actions | iPhone clipboard; accepted Paste input to selected Mac | User Copy or toolbar Paste; no automatic terminal-output clipboard writes | `Components/MARCFileActionSheet.swift`; `MARCSSHKeyViews.swift`; `Screens/MARCTerminalScreen.swift` |
| App Lock | Apple device-owner authentication | Opt-in app entry gate, Face ID or device-passcode result; not per-action biometric protection | `Services/MARCAppLock.swift` `.deviceOwnerAuthentication` |
| Website delivery and analytics | Cloudflare infrastructure / Cloudflare Web Analytics | Page visit; ordinary request metadata and RUM metrics | Live DOM on 27 Oct contained `static.cloudflareinsights.com/beacon.min.js/...`; site source itself has no beacon, consistent with host injection |
| Documentation search | Browser memory and shipped index | User search; no site-code search API | Website `js/docs.js` and `docs-index` JSON |
| Support / external links | Developer and mail provider; GitHub / Apple / selected destination | User email or link; public issues are public | Settings links; policy contact; website support/footer |

## Important corrections

- Passwords do leave iPhone **to the selected Mac** for password authentication;
  they are not sent to a MARC relay. Do not say all secrets never leave the device.
- Private-key authentication signs locally. A user can still deliberately upload
  any selected file or paste a secret into a prompt; the policy does not promise
  protection from intentional disclosure.
- Host-key approval is before authentication. A trusted key is a pin, not a
  third-party verification of ownership. Forgetting a key does not validate a replacement.
- Keychain uses `WhenUnlockedThisDeviceOnly`; no app-enabled iCloud Keychain sync.
  Do not equate this with biometric approval on every secret use or assume app
  uninstall deletes secrets. Backups of app preferences are a separate OS concern.
- Two-hour history pruning stops when the collector stops. It does not remove
  the database or legacy tables, and row deletion is not secure erasure.
- File preview/download and imported uploads create actual temporary copies.
  Temporary protection and cleanup are implemented but not guarantees of deletion.
  Exported copies follow the destination; remote staging/archive cleanup can fail.
- Homebrew Start uses `brew services run`; Stop uses `stop --keep` with a bounded
  wait. Do not describe launch-at-login registration changes. Port Stop is SIGTERM
  for eligible owners with identity checks, not force kill. Docker uses local Unix
  socket context and eligible start/stop states; no remote TCP control, restart,
  creation, deletion, logs or orchestration UI is implemented here.
- API consent is endpoint/session scoped; model catalogue sharing asks separately.
  No terminal output or remote file is automatically included. User prompt text,
  model, instructions and selected API key are transmitted to the actual endpoint.
- Provider-side training, retention, subprocessors, legal safeguards and region
  cannot be inferred from the app's ephemeral networking settings.
- Normal app source contains no developer analytics/crash-reporting SDK calls.
  Apple/platform diagnostics, store operations and archive behavior need separate
  platform review; no packet capture or release-archive review was performed.

## Decisions required before final publication

| Decision / unknown | Prepared draft | Required input or evidence |
| --- | --- | --- |
| Legal operator / controller contact | Existing identity retained: Shivkumar Chougala; contact@getmarc.app | Confirm individual vs actual registered operating entity, and appropriate business/contact address. Do not substitute a planned company. |
| Support provider and retention | Existing 90-day-after-resolution deletion commitment retained, clearly pending confirmation | Name the provider hosting contact@getmarc.app, any forwarding/helpdesk destinations, who can access it, and whether the deletion process is actually followed. Identify backup retention or use accurate qualified wording. Code cannot enforce mailbox retention. |
| Intended ages and markets | No invented age threshold, parental verification, EU/UK representative or worldwide-compliance promise | Confirm target ages, distribution countries and minors' use. Assess child-data obligations and any necessary regional representative, notices, lawful bases and rights handling with counsel for actual operations. |
| Website configuration | Cloudflare analytics disclosed based on the live script; no fixed log-retention period claimed | Confirm analytics remains enabled, Cloudflare plan/configuration, any request logging/export destinations, retention and dashboard access. No Cloudflare account was inspected. |
| Consumer purchase terms | Existing MIT rights, no website subscription checkout, provider charges and donation distinction retained | Confirm current App Store distribution/license and any paid features, purchases or promised sponsor benefits. Future pricing is not authorized by this draft. |
| Legal terms / publication | No new arbitration, exclusive court, governing-law choice or blanket liability waiver added; draft date 27 Oct | Decide dispute/governing-law and eligibility terms appropriate to the actual operator and markets; confirm publication/effective date. Mandatory rights are preserved. |

Do not copy a competitor's worldwide DPDP/GDPR/CCPA compliance statement without
assessing MARC's actual operator, processing, markets and applicable provisions.
This review is a source-grounded drafting exercise, not an opinion that a named
law applies or that an exemption or lawful basis is established. No consent
mechanism for a new business practice was added by editing policy text.

## Official external references checked

Provider pages govern their own practices; only short, general descriptions are
used in the policy so plan-dependent terms are not frozen as universal promises.

- OpenAI: https://developers.openai.com/api/docs/guides/your-data — API data controls and retention depend on endpoint and account controls.
- Google: https://ai.google.dev/gemini-api/terms — paid/unpaid API terms can differ.
- Groq: https://console.groq.com/docs/your-data — usage metadata and conditional customer-data retention/data controls.
- Cloudflare: https://developers.cloudflare.com/web-analytics/data-metrics/data-origin-and-collection/ — beacon and RUM destinations; not cross-customer tracking.
- California Attorney General: https://oag.ca.gov/privacy/ccpa — CCPA applicability is conditional; not a blanket worldwide standard.
- Official Indian and EU pages could not provide usable statutory/commencement text in this run. No detailed commencement or worldwide applicability claim was added. Confirm currently applicable requirements before publication.

## Verification and remaining release work

See `POLICY_AUDIT_VALIDATION.md` for actual test results. No Xcode or Swift compiler
is available here. Run the existing Mac verifier and exact built-bundle policy
checks; test offline Legal screens on iPhone and review App Store disclosures.
No signed app, provider account, mailbox, Cloudflare account, data-processing
agreement, or network packet capture was inspected. Neither these drafts nor
script success certify compliance with every privacy or consumer law.
