# MARC SSH security backport 1

Base: Wellz26/swift-nio-ssh 0.3.7, revision
`d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c`.

Backport: Apple swift-nio-ssh commit
`31cdc3c3391a10460dedf1170530cf651d2ca496` for
CVE-2026-43798 / GHSA-998x-vgvp-xwpc.

NIOSSHSignature.swift rejects ECDSA integer magnitudes wider than the selected
curve before calculating offsets or copying bytes. The helper initializer throws
and its caller propagates the error. Tests cover oversized components, all three
curve widths, leading-zero padding, truncated input and valid signed round trips.

Package.swift retains library and test targets, omits example/performance tools
and the documentation-plugin dependency, and fixes remote dependencies to existing
reviewed versions. Original upstream sources and tests remain in the snapshot.
Original copyright/license headers and Apache-2.0 LICENSE.txt are retained.

This is a modified local snapshot, not a new upstream 0.3.7 release. Its presence
does not establish that the native regression tests or a MARC build have passed.

Source and documentation line-end whitespace is normalized for repository
hygiene. Original upstream file hashes remain recorded in DEPENDENCIES.json;
modified files have separate current hashes. License wording is preserved.
