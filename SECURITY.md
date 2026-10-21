# Security Policy

MARC connects to Macs over SSH and can run commands, access files, and change system settings within the connected account’s permissions. Security reports affecting these operations are welcome.

## Report a vulnerability privately

Email **contact@getmarc.app** with the subject **MARC security report**.

If GitHub’s **Report a vulnerability** option is available in this repository’s Security tab, you can use that private reporting channel instead.

Do not open a public issue with vulnerability details, working exploits, credentials, or private user information.

A useful report includes:

- The affected MARC version or commit.
- Relevant iOS and macOS versions.
- A description of the problem and its potential impact.
- Steps to reproduce it using a system you control.
- A minimal example or redacted logs, if helpful.

Do not send passwords, private SSH keys, API keys, or personal files. Please send the initial report as text rather than an executable attachment.

## What happens next

The maintainer will review the report, ask for clarification if needed, and work toward an appropriate fix. Response and resolution times depend on the report and maintainer availability; there is no guaranteed response deadline.

Please coordinate public disclosure with the maintainer so a fix or practical mitigation can be made available. Reporter credit can be included with your permission.

## Versions

Please include the exact version or commit you tested. Security fixes are generally made on `main`; older builds may require an update to receive a fix.

The project does not currently promise backported fixes or long-term support for specific releases.

## Test responsibly

Only test devices, accounts, and networks you own or have explicit permission to assess.

Use the minimum access needed to demonstrate an issue. Avoid accessing other people’s data, disrupting services, or running destructive commands. Stop testing if you encounter private information.

Areas of particular interest include SSH host verification, credential handling, command construction, file operations, connection lifecycle, and optional AI requests.

## Using MARC securely

- Compare SSH host-key fingerprints before trusting a connection.
- Give Remote Login access only to the accounts that need it.
- Use a secure network route, such as a VPN, for access away from home.
- Review commands and AI suggestions before running them.
- Consider the connected account’s permissions before changing files or processes.
- Read an API provider’s data policies before sending information to it.

General connection problems and feature requests belong in the issue tracker. Use the private reporting channels above when a problem could expose data or allow unauthorized access.
