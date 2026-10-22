# MARC local integration

Base: orlandos-nl/Citadel 0.12.1, revision
`ae8562f895de06ccb86fdb1cbb65fd99c8976e12`.

Runtime source is preserved from that revision. Package.swift selects the sibling
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
