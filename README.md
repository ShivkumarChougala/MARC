# MARC

**Monitor and control your Mac from your iPhone.**

MARC — Macintosh Access & Remote Control — connects to your Mac over SSH. Check system activity, manage processes and files, work in multiple terminal sessions, and adjust everyday controls from one app.

No subscription needed. No MARC account. No ads.

[Website](https://getmarc.app) · [Documentation](https://getmarc.app/docs) · [Report an issue](https://github.com/ShivkumarChougala/MARC/issues)

## Why I built MARC

I wanted a straightforward way to reach my Mac from my iPhone without needing a separate app for monitoring, files, and terminal access.

I also wanted the basics to stay accessible. Opening another terminal session or managing files on my own computer should not need a subscription. MARC brings those tools together, with the source available for anyone who wants to understand, improve, or build on it.

## What you can do

- **Monitor your Mac.** Check CPU activity, memory, battery, storage, network traffic, uptime, and system information.
- **Manage processes.** Search and sort running processes, inspect their resource usage, and terminate a process when needed.
- **Work with files.** Browse folders, preview files, edit supported text files, upload and download, rename, move, and change permissions.
- **Use a full terminal.** Run commands, scroll through output, and keep separate tasks in multiple SSH terminal sessions.
- **Get optional AI assistance.** Use a local Ollama model or configure an API provider for help with commands. Review suggestions before running them.
- **Adjust everyday controls.** Access supported audio, display, wireless, media, and application controls.

Available controls depend on your Mac, macOS version, hardware, and account permissions.

## Get started

You will need:

- An iPhone running **iOS 18 or later**.
- A Mac with **Remote Login** enabled.
- **Python 3** available to your Mac account for monitoring and file operations.
- A network connection that lets your iPhone reach your Mac.

For the first connection:

1. On your Mac, open **System Settings → General → Sharing → Remote Login**. Enable access for the account you want to use.
2. Keep your Mac awake and connect both devices to the same trusted network.
3. In MARC, discover a nearby Mac or add its address manually.
4. Sign in with your Mac account’s short username and password, or a supported SSH key.
5. Compare the SSH host-key fingerprint with your Mac before trusting the connection.

MARC supports OpenSSH Ed25519 private keys.

See the [setup guide](https://getmarc.app/docs) for commands, SSH key setup, and troubleshooting. For access away from home, configure a secure network route such as a VPN.

## Build from source

Clone the repository and open the Xcode project:

```bash
git clone https://github.com/ShivkumarChougala/MARC.git
cd MARC
open MARC.xcodeproj
```

Use an Xcode version that supports the project’s iOS deployment target. Let Xcode resolve the Swift packages, select the **MARC** scheme, and configure your signing team.

Run on a physical iPhone to test nearby discovery, Local Network permissions, and connections to a real Mac.

To run the repository’s verification script on a Mac with Xcode and Python 3 installed:

```bash
bash scripts/verify-marc.sh
```

## Connection and privacy

MARC connects directly to your Mac over SSH using your Mac account’s permissions. It does not require a MARC account or a MARC-hosted relay.

The app checks SSH host keys so you can verify the computer you are connecting to. Take time to compare the fingerprint, especially on the first connection or after a key changes.

AI assistance is optional. Local Ollama models and API providers are configured separately. When you use an API provider, requests go to that provider; its charges and data policies apply.

[Privacy Policy](https://getmarc.app/privacy) · [Terms of Use](https://getmarc.app/terms)

## Contributing

Bug reports, documentation fixes, and focused improvements are welcome.

For a bug report, include what you were trying to do, what happened, steps to reproduce it, and your MARC, iOS, and macOS versions. Remove passwords, private keys, API keys, and personal information from logs and screenshots.

For a larger change, open an issue first so we can discuss the approach. Keep pull requests focused and describe how you tested the change.

## Built with

MARC uses Swift and SwiftUI, with:

- [Citadel](https://github.com/orlandos-nl/Citadel) for SSH connectivity.
- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) for terminal emulation.

See [third-party notices](THIRD_PARTY_NOTICES.md) for dependency acknowledgements and license information.

## Support the project

If MARC is useful to you, reporting a bug, improving the documentation, or sharing the project helps.

You can also [support development](https://getmarc.app/support).

## License

MARC is available under the [MIT License](LICENSE). Third-party dependencies retain their respective licenses.

Built by [Shivkumar Chougala](https://github.com/ShivkumarChougala).
