# MARC local integration

Base: orlandos-nl/Citadel 0.12.1, revision
`ae8562f895de06ccb86fdb1cbb65fd99c8976e12`.

Runtime source starts from that revision, with the MARC parser changes described
below. Package.swift selects the sibling
local swift-nio-ssh security backport and fixes its remaining remote dependencies
to the existing reviewed versions. The example executable and its ColorizeSwift
requirement are omitted from the local manifest; library and test targets remain.
This does not remove application features. Upstream sources for examples remain
available in this snapshot, but the example is not a package product here.

Original copyright notices, embedded notices and MIT LICENSE are retained.

Source and documentation line-end whitespace is normalized for repository
hygiene. Original upstream file hashes remain recorded in DEPENDENCIES.json;
modified files have separate current hashes. License wording is preserved.

Swift Crypto is pinned to 5.0.3 to include the upstream RSA key-parsing and
VOPRF input-length fixes. This dependency change is additional to the upstream
base snapshot; the SSH ECDSA parser backport remains in place.

OpenSSH private-key parsing now rejects mismatched cipher/KDF combinations,
empty or misaligned private payloads, trailing envelope/public-key bytes and
malformed bcrypt options. AES key and IV lengths are checked before native
crypto calls, and context-allocation failure throws. Every padding byte is
validated, including the final byte and a full block emitted by the encoder.
The existing bcrypt work-factor ceiling remains unchanged. MARCOpenSSHKeyTests
adds malformed-input and valid-key regressions, including disposable encrypted
AES-128/AES-256 fixtures and signing checks.

Buffered command execution now reserves total stdout/stderr bytes before async
queueing, excludes discarded stderr from returned output while counting it toward
the total budget, and fails on a full 256-chunk queue instead of returning partial
success. Exact byte copies avoid retaining larger backing allocations. Cancellation,
setup failure, overflow and completion close only the affected command child channel;
a cancellation recorded before child creation rejects the late channel. The generic
streaming/interactive path remains unchanged. MARCBufferedCommandTests exercises
budgets, producer-handler integration, stream errors, shell dispatch and lifecycle.
NIOEmbedded is added only to the test target, from the existing pinned NIO package.
