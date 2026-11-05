# Terms of Use

Effective 6 November 2026

MARC is an open-source iPhone app for monitoring and controlling your Mac. These Terms of Use explain what we provide and your responsibilities when you use our app or website.

Connect only to Macs and accounts you’re authorized to use. Review commands and file or service changes before confirming them, because they can affect your Mac and the work running on it.

AI command suggestions are optional. Review any suggestion before running it. These terms do not change the rights granted by the MIT License or any rights that cannot lawfully be limited.

Contact: contact@getmarc.app

Published version: https://getmarc.app/terms

## About MARC and these terms

In these terms, “we,” “us” and “our” refer to the provider of MARC, and “the app” means the MARC iPhone app.

If you download MARC from the App Store, Apple’s applicable store terms and app license also apply.

[Apple’s Standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)

[Privacy Policy](https://getmarc.app/privacy)

## Authorized access and account permissions

Use the app only with devices, accounts, files and services you own or have permission to access. Follow applicable law, organizational rules and the terms of any service you use. Do not use the app to gain unauthorized access, steal credentials, disrupt systems or disclose information without permission.

Remote actions run with the permissions of the connected Mac account and its tools. A successful login does not give you permission to perform every action.

## Setup, connections and verification

You need a compatible iPhone and a reachable, awake Mac with Remote Login enabled. Monitoring and file helpers need Python 3 available to the SSH account. Some controls require compatible hardware or additional tools.

Sign in with an authorized password or SSH key. Verify the Mac’s SSH fingerprint before trusting it, and investigate unexpected changes. We do not provide a hosted relay; if you connect from outside your local network, configure a secure route to your Mac.

## Commands, processes and file operations

Terminal commands run as the connected Mac user and can contact external services. File edits, transfers, permission changes and deletions affect real data. Review the target and destination before confirming an action, and keep backups of important files.

Stopping a process can interrupt work or lose unsaved data. Canceling, disconnecting or closing the app does not undo completed actions. Running jobs or temporary files can remain on your Mac. Copies you save or share elsewhere are managed at their destination.

Monitoring uses system and network resources and can save history on your Mac. Readings may be delayed, incomplete or unavailable. Alerts depend on the readings the app receives and iOS delivery settings; do not rely on them for continuous background monitoring or as your only safeguard. See the Privacy Policy for what the app reads and stores.

[Privacy Policy](https://getmarc.app/privacy)

[How MARC works](https://getmarc.app/docs/how-marc-works)

## Services, containers and system controls

Stopping an eligible process sends a termination request. One process can serve several ports, and a service manager may start it again.

Homebrew Start runs a supported service without registering it at login; Stop preserves any existing registration. Docker Start and Stop require a local Unix socket and an eligible container state. Controls depend on your Mac, installed tools and account permissions. Helpers, apps and services you start may create files or logs and make their own network connections.

## Optional AI and third-party charges

AI command suggestions are off by default. The app can use Ollama on your Mac or an API provider you choose. External providers set their own terms, quotas and charges. The Privacy Policy explains what is sent and when the app asks for permission. Only send information you’re authorized to share.

AI suggestions can be wrong or destructive. They do not run automatically. Tapping Run sends the command and Return to the active terminal. Review the command and make sure you’re at an empty shell prompt before running it.

Turning off AI, canceling a request or removing a key from the app does not erase information already sent, revoke the provider’s key or reverse charges.

[Privacy Policy](https://getmarc.app/privacy)

## Open-source licensing

MARC’s source code is licensed under the MIT License, copyright © 2026 Shivkumar Chougala. Use, modification and redistribution are subject to that license, including its notice requirements. These terms do not withdraw those permissions.

Dependencies, tools and services may have separate licenses and notices. Review and preserve applicable notices when distributing a build.

[MIT License](https://github.com/ShivkumarChougala/MARC/blob/main/LICENSE)

[Third-party notices](https://github.com/ShivkumarChougala/MARC/blob/main/THIRD_PARTY_NOTICES.md)

## Availability, support and sponsorship

We may change features and compatibility between releases. We do not guarantee uninterrupted access, complete readings or support response times.

Optional GitHub sponsorship supports development and does not unlock app features.

## Warranties, liability and statutory rights

To the extent permitted by law, MARC’s MIT-licensed software is provided as is under the MIT License’s warranty and liability provisions.

These terms do not limit rights, remedies or liability that cannot lawfully be limited. Apple and other providers remain responsible for their own obligations.

## Changes to these Terms and contact

We may revise these terms as the app and website change. We update the date above when we publish a revision and provide notice or seek agreement where required. Revisions do not withdraw existing MIT license permissions or limit mandatory rights.

MARC is provided by Shivkumar Chougala. For questions about these terms, email contact@getmarc.app. For bugs and ideas, use the repository’s issue tracker. Do not include passwords, private keys, API keys or unredacted sensitive logs.

[Contact about terms](mailto:contact@getmarc.app?subject=MARC%20terms)

[Report an issue](https://github.com/ShivkumarChougala/MARC/issues/new?title=Bug%20report)
