# Connect your Mac to MARC

MARC runs on iPhone with iOS 18 or later. It connects directly to your Mac over SSH.

## Prepare the Mac

1. Connect the iPhone and Mac to the same local network for the first connection.
2. On the Mac, open System Settings → General → Sharing → Remote Login.
3. Enable Remote Login and allow the account you intend to use. Prefer selected users.
4. Use the Mac account's short username, not its display name or Apple Account email.
   Run `whoami` in the Mac's Terminal if unsure.
5. Check `python3 --version` in that account's Terminal. MARC's monitoring and
   file-action scripts require Python 3. If missing, install Python 3 and verify
   that `ssh username@mac-address 'python3 --version'` also works.

Keep the Mac awake and reachable. A sleeping Mac may not accept a connection.
MARC does not automatically expose your Mac to the internet.

## Add it on iPhone

Allow Local Network access when prompted. In MARC, scan Nearby Macs and select
your Mac, or add its address manually. The usual SSH port is 22; use your
configured port if different. Authenticate with your account password or an SSH key.

Compare the host fingerprint before trusting it. On the Mac, show its public
host-key fingerprints with:

```bash
for key in /etc/ssh/ssh_host_*_key.pub; do
    ssh-keygen -lf "$key" -E sha256
done
```

Match the fingerprint and key type MARC presents. A changed fingerprint needs
investigation; do not accept it merely to dismiss a warning.

## Optional controls

Monitoring, Terminal and file browsing do not require the optional media helper.
For browser media, open MARC's media setup panel and follow its detected setup
instructions. If it offers an install command, copy it to MARC's Terminal,
review and run it, then return to check setup again. Bluetooth switching may
require `blueutil`. Quick Launch operates in the signed-in Mac user's session.

Some external monitors do not expose brightness adjustment, and some HDMI or
display audio outputs have fixed volume. An unsupported control is not proof
that SSH is broken. Mac permissions and installed helper tools also affect availability.

## Files, history and AI

File actions use your SSH account's permissions. Preview/download creates a
temporary copy on iPhone; exporting or sharing can create a separate copy in
the destination you choose. Upload replacement requires confirmation. Test
deletion and replacement with disposable files first.

Statistics history is stored on each Mac under the SSH account at
`~/.local/share/marc/history.sqlite`. Removing a profile on iPhone does not
delete that remote history or your Mac's files.

AI is optional. Local AI uses the configured service through the Mac. API mode
sends the prompt and selected model to your configured HTTPS provider, with
the configured API key when present. Check that provider's privacy and
retention terms. Review generated commands before explicitly running them.

## If discovery or connection fails

Check Remote Login, account permissions, the SSH port, Local Network permission,
and whether guest Wi-Fi isolates devices. Try the Mac's current address manually.
If a password is rejected, check the short username and account password.
Never share passwords, private keys or API keys in screenshots or logs.
