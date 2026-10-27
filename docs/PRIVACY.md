# Privacy Policy

Effective 27 October 2026

MARC (Macintosh Access & Remote Control) connects your iPhone to your Mac to monitor activity, manage files and processes, run terminal commands, and use supported system, service and Docker controls. This Privacy Policy explains what information these features process, where it is stored, when it is shared, and the choices available to you. It applies to the MARC iPhone app and getmarc.app.

Contact: contact@getmarc.app

Published version: https://getmarc.app/privacy

## Scope and responsibility

MARC connects directly to the Mac you select over SSH. Normal monitoring, terminal use and file transfers do not pass through a MARC-operated relay or send their contents to the developer. There is no MARC account, advertising SDK, in-app behavioral analytics or cross-app tracking in this version.

The app processes information on your iPhone and your selected Mac to provide the features you use. Optional API AI, website hosting, support messages and services you choose to open involve separate recipients described below.

MARC is currently provided by Shivkumar Chougala. Questions about the app, website or this policy can be sent to contact@getmarc.app. This contact handles support and website information; it cannot delete records controlled by your Mac administrator or an external provider.

## Connections, permissions and host verification

Connection setup processes the Mac name or label, host address, SSH port and username. Nearby discovery browses local Bonjour SSH services (_ssh._tcp), including advertised names and connection addresses. Resolving hostnames may involve your network’s DNS or local name-resolution services.

Monitoring and process views read system measurements, account and device details, and process names, identifiers and resource use from the Mac. Supported controls can read display and audio-output names and settings, Wi-Fi and Bluetooth state, installed application names and bundle identifiers, and Now Playing title, artist and source when available. These results travel from the Mac to your iPhone over SSH, not to an AI provider by default.

MARC obtains your approval of a new SSH host identity before starting authentication. Trust is stored for the host and port. Later connections check the host key against the stored identity; an unexpected change blocks the connection. Compare the displayed SHA256 fingerprint with the Mac itself before approving it. Remembering a key does not independently prove who owns the Mac.

Password authentication sends the username and password to the selected Mac within the encrypted SSH connection. SSH-key authentication uses the private key locally to sign authentication messages; the normal authentication flow does not upload the private key or its passphrase. The Mac receives the public authentication information needed to verify the login.

Commands, queries and file operations run with the connected account’s permissions and any access available to that account or its tools. MARC does not provide a separate permission sandbox on the Mac. Your Mac, network administrator and services you use may retain connection, command or activity logs.

## Profiles, credentials and device storage

Saved Mac profiles and preferences are stored in the app’s iPhone preferences. They include profile identifiers, names, addresses, usernames and ports; appearance and refresh choices; selected models and API endpoint settings; remembered folders; Quick Launch choices; guided-tour progress; and per-Mac Services or Docker tab choices. These preferences are not stored as secrets in Keychain.

Saved connection credentials, imported SSH private keys and passphrases, trusted host keys and saved API keys use Apple Keychain with WhenUnlockedThisDeviceOnly accessibility. MARC does not enable iCloud Keychain synchronization for these records. They are accessible to the app while the device is unlocked; this is not a separate biometric prompt for every credential use.

Credentials are read into memory when needed for a connection or request. Live system readings, process lists, terminal content and the current connection’s service or Docker read cache are held in app memory. This version does not write that service cache to disk. The remote shell and remote services can retain their own history or logs.

App preferences, system diagnostics and existing device backups are also subject to iOS settings and Apple’s platform behavior. MARC does not implement its own cloud backup or synchronization service. This policy does not promise that uninstalling the app removes Keychain records or copies in existing backups.

## File transfers and temporary copies

Browsing files sends directory and metadata requests to your Mac. Preview and Download transfer selected file contents from the Mac to your iPhone over SFTP through SSH. Upload sends selected file contents from your iPhone or a selected file provider to the Mac. A file picker or provider may obtain its own cloud-backed content when you select it.

MARC creates app-owned temporary files for downloads, previews and imported upload content. On iOS it applies and verifies Complete Protection before writing content, uses private file permissions, and marks its temporary directories as excluded from backup. It attempts to remove a temporary copy when its transfer, preview or sharing use ends. Startup cleanup attempts to remove recognized abandoned MARC temporary folders. Cleanup can fail, and a temporary file may remain until a later cleanup or system removal.

Downloaded files you save to Files, share, or open in another app become separate copies handled by the destination you select. MARC does not delete those copies when its temporary file is removed. Uploads and edits can create staging files on your Mac; an interrupted connection can leave a staging file when remote cleanup cannot be confirmed. Downloading a folder first creates a temporary archive on the Mac; MARC attempts to remove that archive after the transfer.

Rename, move, replacement, permission changes and deletion affect real files on the Mac. MARC’s supported replacement flow attempts to preserve applicable file metadata and quarantine information. It cannot undo changes already completed or control the retention and backups of destination services.

## Monitoring history on your Mac

While the monitoring collector is running, it attempts to save samples about every five seconds in ~/.local/share/marc/history.sqlite under the connected Mac account. A sample includes usage and activity measurements and context such as hostname, username, local IP address, Mac model, operating-system version, architecture, network interface, uptime and available power readings. This history is not just anonymous CPU percentages.

The collector periodically deletes its own sample rows older than two hours while active. It does not schedule deletion after monitoring stops. The database remains on the Mac, and older collector tables are left in place. Row pruning is not a secure-erasure guarantee and does not remove backups or other logs.

Removing a saved Mac from MARC does not delete that database or other remote files. The Mac account owner or administrator can remove the database separately. Current chart buffers on iPhone are held in app memory.

## Services and Docker

MARC reads listening TCP ports, process identifiers and names, listening addresses, supported Homebrew background service states, and local Docker container identifiers, names, images, states and status. These queries run on the Mac over SSH. The current connection’s latest results are cached in app memory for display while refreshing.

Start, Stop and Stop process requests are sent when selected. Eligible port-process stops use a termination request, subject to ownership and protected-process checks. Homebrew controls use the Mac’s Homebrew service commands. Docker controls require a local Unix-socket Docker connection on the Mac; remote Docker hosts over TCP are not supported by this view.

Processes, Homebrew services, Docker and the applications inside containers may keep their own logs or make their own network connections, including as a consequence of starting a service or container. They are not made private or isolated by MARC.

## Optional AI and destination consent

AI starts Off. Local mode sends the prompt, selected model and command-generation instructions over SSH to Ollama on your selected Mac, using its loopback service. Installed-model discovery also queries that local Ollama service. The model and Ollama configuration determine any further processing, logs or network activity; MARC cannot guarantee that every locally configured model is offline.

API mode sends an HTTPS request from your iPhone to the configured endpoint. The payload contains your submitted prompt, selected model and instructions to suggest a shell command. The selected API key is sent as an authentication header when configured. The recipient also receives your public IP address and ordinary request and connection metadata.

The built-in presets are OpenAI (api.openai.com), Google Gemini (generativelanguage.googleapis.com), and Groq (api.groq.com). A custom HTTPS endpoint sends these requests to that endpoint’s operator. No MARC-operated AI proxy is used.

Before the first prompt to an endpoint in the current Terminal session, MARC displays the destination host and requests permission. Approval allows further prompts to that endpoint in that session; it is not a new consent prompt for every generation. Connection or relevant configuration changes invalidate approval. Each generation still requires your action.

Loading a built-in provider’s model catalogue requires separate approval. It sends the selected API key and connection metadata to that provider, not your command prompt, terminal output or files. Custom endpoints use a manually entered model ID rather than this built-in catalogue loader.

MARC does not automatically attach terminal output, remote files, Mac passwords or SSH private keys to an AI request. Text you type or paste into the prompt is sent as part of that prompt. Do not include information you are not authorized to share. API requests use an ephemeral network session with cookies and persistent URL caching disabled, and do not follow HTTP redirects.

Provider retention, training, human review, subprocessors and processing locations depend on the provider, account, plan and configuration. They can change. MARC does not impose zero retention or a no-training setting on your provider account. Review the provider’s current data controls and terms before sending information.

Cancel a pending request or switch AI Off to stop future requests. Cancellation cannot recall information already transmitted. Removing an API key in MARC neither revokes it at the provider nor deletes the provider’s records. Use the provider’s controls or privacy contact for those actions.

An AI suggestion runs only after you tap Run. Run sends the command followed by Return to the active terminal. Review it first and use an empty shell prompt; MARC cannot determine which program is reading that terminal.

[OpenAI API data controls](https://developers.openai.com/api/docs/guides/your-data)

[Google Gemini API terms](https://ai.google.dev/gemini-api/terms)

[GroqCloud data controls](https://console.groq.com/docs/your-data)

## Device permissions and deletion choices

Local Network permission supports nearby discovery and connections. Optional App Lock uses Apple’s device-owner authentication, which can allow Face ID or device passcode. MARC receives an authentication result, not facial templates. App Lock controls entry to the app; it does not add an approval prompt to every remote action.

File and photo pickers let you choose upload content. Preview uses the system preview interface; sharing uses the system share interface. Permission settings and the selected provider or destination control their additional processing.

Explicit Copy actions can place a file path, public SSH key or setup command on the iPhone clipboard. The Terminal toolbar Paste action reads clipboard text when tapped and sends accepted input to the active Mac terminal. MARC does not automatically copy remote terminal output to the clipboard.

Removing a saved Mac first attempts to delete its saved connection credential. After that succeeds, MARC removes the profile and its per-Mac preferences. Reusable SSH keys, trusted host identities and global AI settings are managed separately in Settings and Keychain. Removing a reusable SSH key is separate from removing its public key from the Mac’s authorized keys.

You can remove saved SSH keys, API keys and trusted fingerprints through Settings → Keychain, disable AI or App Lock, and change iOS permissions. Remove saved secrets before uninstalling when you want them deleted. Uninstalling does not reliably delete Keychain records, remote history, shared files, provider records or existing backups.

## Support, retention and privacy requests

Emailing support discloses your sender address, message, attachments and ordinary email metadata to the support operator and the email services carrying and storing that correspondence. The content is used to answer the request and resolve problems. Do not include passwords, private SSH keys or API keys.

Resolved support correspondence is deleted from active support records within 90 days after resolution unless longer retention is legally required. Email-provider systems and existing backups can have different retention. This period does not apply to your Mac, AI providers or shared destinations.

For questions or requests concerning access, correction or deletion of support or website information, contact contact@getmarc.app. Verification proportionate to the request may be required. Depending on applicable law, you may also have rights to object, restrict processing, withdraw consent or complain to a competent authority. Rights and exceptions depend on the relevant processing and jurisdiction; this policy does not promise identical rights everywhere.

There is no MARC account to delete. For data controlled by your Mac administrator, AI provider, email provider or a destination you selected, use that party’s own settings and request process.

[Contact about privacy](mailto:contact@getmarc.app?subject=MARC%20privacy)

## Website hosting and external recipients

getmarc.app is hosted through Cloudflare Pages. Requests to load the site disclose IP address, requested URL, browser and device information, and ordinary HTTP metadata to the hosting infrastructure for delivery, security and diagnostics. Network intermediaries such as your DNS resolver may also process the information needed to connect.

The deployed website loads Cloudflare Web Analytics to measure visits, page views and performance. The beacon loads from static.cloudflareinsights.com and submits analytics to Cloudflare, normally through /cdn-cgi/rum on a Cloudflare-proxied site. Cloudflare describes Web Analytics as cookie-free and not tracking individual visitors across its customers’ websites. This is separate from operational hosting or security records; cookie-free does not mean that no information leaves your browser.

The MARC website does not offer advertising, a newsletter signup, a MARC login, or a website payment form. Its documentation search runs against a bundled index in your browser rather than sending your query to a MARC search server.

Links to GitHub, GitHub Sponsors, Apple, Homebrew or AI-provider pages connect to those services when opened. Support email uses your email app and email providers. Sponsor or store transactions take place with the selected service, not a MARC website checkout. Public issues and comments on GitHub can be visible to others. Those services apply their own terms and data practices.

Third parties may process information in countries other than yours. Their infrastructure, account settings and applicable agreements determine location and retention; MARC does not promise domestic-only processing or a fixed deletion period for third-party hosting, analytics or provider records.

[Cloudflare privacy policy](https://www.cloudflare.com/privacypolicy/)

[Cloudflare analytics collection](https://developers.cloudflare.com/web-analytics/data-metrics/data-origin-and-collection/)

[GitHub privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement)

## Open-source transparency

MARC’s source code is available under the MIT License. The repository includes third-party license notices. Source transparency helps explain implemented behavior but does not replace your device, network or provider security controls.

[Review MARC on GitHub](https://github.com/ShivkumarChougala/MARC)

## Policy updates

The date above identifies this version. The website can publish a newer policy before an installed app receives an updated bundled copy. Settings → Legal displays bundled documents offline and offers an explicit link to the published version. Opening a link or sending email involves that destination’s normal connection processing.

Changes to this policy do not replace consent or notices required for a new use of information. Material changes will be described in the updated policy and, where required, through additional notice.
