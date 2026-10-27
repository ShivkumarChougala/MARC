# Terms of Use

Effective 27 October 2026

These Terms of Use govern use of the MARC iPhone app and getmarc.app, including SSH connections, monitoring, terminal commands, file transfers, supported controls and optional AI assistance. They explain permitted use, user responsibilities and the relationship between the app, third-party services and MARC’s open-source license.

Contact: contact@getmarc.app

Published version: https://getmarc.app/terms

## About MARC and these terms

MARC (Macintosh Access & Remote Control) is currently provided by Shivkumar Chougala. MARC connects your iPhone to a Mac you are authorized to access. Questions about these terms can be sent to contact@getmarc.app.

These terms do not replace or restrict permissions granted by MARC’s MIT source-code license. If you obtain the app through Apple’s App Store, the applicable Apple store terms and app license also apply. Mandatory consumer and other statutory rights remain unaffected.

[Apple’s Standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)

[Privacy Policy](https://getmarc.app/privacy)

## Authorized access and account permissions

Connect only to devices, accounts, files and services you own or have permission to use. Comply with applicable law, organizational rules and the terms of services you connect to. Do not use MARC for unauthorized access, credential theft, disruption or disclosure of information you are not entitled to share.

Remote actions use the connected Mac account and the access available to that account or its tools. A successful login does not establish that every action is authorized. MARC is not a separate sandbox or access-control policy for your Mac.

## Setup, connections and verification

MARC requires a compatible iPhone running iOS 18 or later, a compatible Mac with SSH Remote Login enabled, Python 3 available to the connected account for monitoring and helper queries, and a working network route. Some features require additional tools, permissions or compatible hardware.

Nearby discovery finds advertised local SSH services. Use the Mac account’s short username and an authorized password or SSH key. New host identities require approval before authentication. Verify the SHA256 fingerprint on the Mac; investigate unexpected key changes before changing stored trust.

MARC does not provide a hosted remote-access relay. Access outside the local network requires secure networking that you configure separately. Compatibility, networking and macOS restrictions can prevent a connection or a control from working.

## Commands, processes and file operations

Terminal input executes on the Mac as the connected user. Commands can access networks or third-party services according to what you run. Monitoring and process readings are informational and may be incomplete, delayed or unavailable.

Uploads, replacements, edits, rename or move operations, permission changes and deletion affect real data. A preview or download creates a local copy; saving or sharing it creates a separate destination copy. MARC’s cleanup does not remove copies you save elsewhere. Confirm the item and destination and keep backups.

Process termination can interrupt work or lose unsaved data. An interrupted connection, canceled request or closed app cannot necessarily reverse a command, transfer or other operation already completed. Remote temporary files can remain if cleanup cannot be confirmed.

## Services, containers and system controls

Services & Docker shows listening TCP ports, supported Homebrew background services and local Docker containers. Stop process is limited to eligible processes and uses a termination request rather than a guaranteed immediate stop. Stopping one process can affect several ports, and a service manager may start it again.

Homebrew Start runs a supported service without adding launch-at-login registration; Stop preserves its existing registration. Docker Start and Stop require a local Unix-socket Docker connection and an eligible current container state. This view does not provide remote TCP Docker management, container creation, removal, logs or restart controls.

Service, container and system-control actions may interrupt applications or expose or stop services according to their own configuration. Volume, brightness, Bluetooth, media and other controls depend on macOS, hardware, installed tools and permissions. MARC does not guarantee every control on every setup.

## Optional AI and third-party charges

AI is optional and starts Off. Local mode uses Ollama on the selected Mac. API mode uses your chosen endpoint, model and credentials. Provider availability, quotas, charges and data practices are controlled by that provider and your account; displaying a model does not establish free access.

MARC asks for endpoint approval for the current Terminal session before API prompt sharing, and separately asks before loading a built-in provider’s model list. Review the Privacy Policy and destination before allowing either operation. You are responsible for having permission to send the information in your prompt.

AI output can be incorrect, inappropriate or destructive. Suggestions do not execute automatically. Tapping Run sends the suggested command and Return to the active terminal. Review the command and use an empty shell prompt after exiting any running program and clearing partially typed input. MARC cannot detect which program is reading the terminal or guarantee command safety.

Third-party services have their own terms, licenses, fees and privacy rules. Disabling AI, canceling a request or deleting a local key does not erase information already sent, revoke the provider key or undo charges already incurred.

[Privacy Policy](https://getmarc.app/privacy)

## Open-source licensing

MARC’s source code is licensed under the MIT License, copyright © 2026 Shivkumar Chougala. Use, modification and redistribution are subject to that license, including its notice requirements. These terms do not withdraw those permissions.

Dependencies, tools and services may have separate licenses and notices. Review and preserve applicable notices when distributing a build.

[MIT License](https://github.com/ShivkumarChougala/MARC/blob/main/LICENSE)

[Third-party notices](https://github.com/ShivkumarChougala/MARC/blob/main/THIRD_PARTY_NOTICES.md)

## Availability, support and sponsorship

Features and compatibility may change between releases. Uninterrupted connections, complete or error-free readings, support response times and availability of external services are not guaranteed. The website’s download section identifies the available distribution route and release status.

The MARC website does not currently sell an AI plan or begin a recurring MARC subscription. External AI providers can charge for their services. Optional sponsorship supports development and does not purchase app features. Any future paid offering requires its own clearly disclosed purchase terms rather than an assumption that these terms already describe it.

## Warranties, liability and statutory rights

To the extent permitted by applicable law, the MIT-licensed software is provided as is and the MIT License’s warranty and liability provisions apply. Review consequential actions and maintain backups rather than relying on MARC as your only safeguard.

Nothing in these terms excludes liability, remedies or consumer rights that cannot lawfully be excluded. The applicable law and the facts determine the effect of these provisions. Apple and other providers remain responsible for their own obligations under their terms and applicable law.

## Updates and contact

The date above identifies this version. Updates do not retrospectively remove permissions granted under the MIT License or rights protected by mandatory law. Where additional notice or agreement is required for a material change, a changed date alone does not replace it.

For questions about these terms, contact contact@getmarc.app. For bugs and ideas, use the repository’s issue tracker. Do not include passwords, private keys, API keys or unredacted sensitive logs in reports.

[Contact about terms](mailto:contact@getmarc.app?subject=MARC%20terms)

[Report an issue](https://github.com/ShivkumarChougala/MARC/issues/new?title=Bug%20report)
