# MARC App Review handoff

Paste the draft below into App Review Notes after replacing the placeholders and testing the setup from outside your local network. Keep reviewer credentials in App Store Connect, out of Git and public documentation.

> MARC is an iPhone app that monitors and controls a Mac over SSH. It connects directly to the Mac; no MARC account is required. We have prepared a test Mac with Remote Login and Python 3 available to the SSH user.
>
> Test host: [reachable hostname or IP]. SSH port: [port]. Use the temporary test credentials supplied in App Review Information. Expected SSH host fingerprint: [SHA256 fingerprint].
>
> Open MARC, add a Mac manually, enter the host and port, and verify the displayed fingerprint. Connect with the supplied account. In Status, check live readings. Open Processes to see the process list, Files to preview or download the supplied sample file, and Terminal to run `whoami`. Use the sample folder for file changes.
>
> AI suggestions are optional and disabled by default. You can test the core app without setting up an AI provider or supplying an API key.

## Before submitting

- Prepare a dedicated Mac and a temporary, restricted SSH test account with sample files and no personal data. Keep the Mac reachable and awake during review. Verify Remote Login, Python 3, the host fingerprint, and the exact test flow from an outside network. Document any optional setup needed for features presented for review. Remove access after review.
- In the release build, configure an external AI endpoint you control for testing and use synthetic input. Check the endpoint’s request log: Cancel sends no request; Allow and Send reaches the named endpoint; a new endpoint or SSH connection prompts again. Test built-in provider model loading separately: Cancel skips the request; Allow and Load loads the catalogue. Confirm the app is usable with AI off.
- Publish the updated policy pages, then verify the live Privacy URL opens without a login and matches the copy linked from Settings → Legal and entered in App Store Connect. Inspect the signed archive and dependency privacy manifests. Reconcile the App Privacy answers with the actual build, including external AI and the applicable providers’ data practices. Do not infer the answers from the absence of a MARC account or relay.
- Confirm the support mailbox follows the policy: keep conversations while open and for 90 days after resolution, then normally delete them from active records at the next monthly review. If actual practice differs, update the policy before publishing.
