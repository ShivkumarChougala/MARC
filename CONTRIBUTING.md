# Contributing to MARC

Thanks for taking an interest in MARC. Bug reports, documentation fixes, testing, and focused code improvements all help.

For a substantial feature or a change to the app’s behavior, please open an issue before starting implementation. This gives us a chance to discuss the approach and avoid duplicate work.

## Report a bug

Search existing issues first. If you do not find a matching report, open a new issue with:

- What you were trying to do.
- What you expected and what happened instead.
- Steps that reproduce the problem.
- Your MARC build, iOS version, and macOS version.
- Relevant screenshots or logs, with sensitive information removed.

Never include passwords, private keys, API keys, or personal files. Check terminal output, addresses, usernames, and file paths before sharing them.

Report suspected security vulnerabilities privately using [SECURITY.md](SECURITY.md).

## Suggest an improvement

Explain the problem you want to solve and how the proposed change would help. Examples of the current workflow are useful.

Small improvements are welcome. A new dependency, a major interface change, or a feature that affects connection security should be discussed first.

## Set up the project

You will need a Mac with Xcode and Python 3.

```bash
git clone https://github.com/YOUR-USERNAME/MARC.git
cd MARC
open MARC.xcodeproj
```

Fork the repository first and replace `YOUR-USERNAME` with your GitHub username.

Let Xcode resolve the Swift packages. Select the **MARC** scheme and configure your signing team before running on a physical iPhone. Use an Xcode version that supports the project’s iOS deployment target.

For connection testing, use a Mac and account you control with Remote Login enabled. Test file operations and process controls on disposable files and processes.

## Make a change

Create a branch for your work:

```bash
git switch -c fix/describe-your-change
```

Follow the surrounding Swift and SwiftUI code. Keep changes focused and preserve working behavior outside the task.

Pay particular attention to:

- Connection cleanup when a task ends or a screen closes.
- Clear progress, cancellation, and error handling.
- Host-key verification and account permissions.
- Keeping credentials and sensitive data out of logs.
- Accessibility, keyboard behavior, and smaller screens.

Avoid unrelated formatting changes or generated build files. Do not commit signing credentials, provisioning profiles, personal Xcode settings, or local backups.

## Check your work

Run the repository’s verification script on your Mac:

```bash
bash scripts/verify-marc.sh
```

Test the behavior you changed on a physical device when it involves discovery, SSH, files, terminal input, or Mac controls. Automated checks do not replace testing a real connection.

Add or update a focused check when fixing a behavior that can reasonably be tested. If you cannot run a relevant check, explain that in the pull request.

## Open a pull request

Describe:

- The problem and resulting behavior.
- How you tested the change.
- Any remaining concerns a reviewer should know about.

Include screenshots or a short recording for interface changes when useful. Link the related issue if there is one.

Pull requests may need discussion or revision before merging. Please keep feedback respectful and follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Website and documentation

The public website lives in `web/`. Repository documentation lives in `docs/`. Keep changes in the appropriate location and check relative links.

For website changes, serve the site over HTTP so shared components can load:

```bash
python3 -m http.server 8000 --directory web
```

Open `http://localhost:8000`, then check the affected pages at desktop and phone widths.

## License

By submitting a contribution, you agree that your contribution may be distributed under the repository’s [MIT License](LICENSE).

Only submit work you have the right to contribute. Keep third-party license notices intact and identify any new dependencies in your pull request.
