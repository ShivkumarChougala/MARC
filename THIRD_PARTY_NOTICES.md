# Third-party notices

MARC uses the following Swift packages. Their licences remain separate from MARC's own licence. The supplied licence and notice files are preserved verbatim under `licenses/third-party/`.

Versions and revisions come from the uploaded `Package.resolved`, matched to the user's Xcode checkouts by the collection script. Recheck these notices when dependencies change.

| Package | Version | Main licence | Retained notices |
| --- | --- | --- | --- |
| [bigint](https://github.com/attaswift/BigInt.git) | 5.7.0 | MIT | [Files](licenses/third-party/bigint/) |
| [citadel](https://github.com/orlandos-nl/Citadel) | 0.12.1 | MIT | [Files](licenses/third-party/citadel/) |
| [h](https://github.com/rarestype/h) | 1.0.1 | Apache-2.0 | [Files](licenses/third-party/h/) |
| [swift-argument-parser](https://github.com/apple/swift-argument-parser) | 1.8.2 | Apache-2.0 with Swift Runtime Library Exception | [Files](licenses/third-party/swift-argument-parser/) |
| [swift-asn1](https://github.com/apple/swift-asn1.git) | 1.7.3 | Apache-2.0 | [Files](licenses/third-party/swift-asn1/) |
| [swift-atomics](https://github.com/apple/swift-atomics.git) | 1.3.1 | Apache-2.0 with Swift Runtime Library Exception | [Files](licenses/third-party/swift-atomics/) |
| [swift-collections](https://github.com/apple/swift-collections.git) | 1.7.2 | Apache-2.0 with Swift Runtime Library Exception | [Files](licenses/third-party/swift-collections/) |
| [swift-crypto](https://github.com/apple/swift-crypto.git) | 3.15.1 | Apache-2.0 | [Files](licenses/third-party/swift-crypto/) |
| [swift-log](https://github.com/apple/swift-log.git) | 1.16.1 | Apache-2.0 | [Files](licenses/third-party/swift-log/) |
| [swift-nio](https://github.com/apple/swift-nio.git) | 2.104.0 | Apache-2.0 | [Files](licenses/third-party/swift-nio/) |
| [swift-nio-ssh](https://github.com/Wellz26/swift-nio-ssh.git) | 0.3.7 | Apache-2.0 | [Files](licenses/third-party/swift-nio-ssh/) |
| [swift-png](https://github.com/tayloraswift/swift-png) | 4.5.1 | Apache-2.0 | [Files](licenses/third-party/swift-png/) |
| [swift-system](https://github.com/apple/swift-system.git) | 1.8.1 | Apache-2.0 with Swift Runtime Library Exception | [Files](licenses/third-party/swift-system/) |
| [swiftterm](https://github.com/migueldeicaza/SwiftTerm.git) | 1.99.0 | MIT | [Files](licenses/third-party/swiftterm/) |

## Bundled components

SwiftNIO includes llhttp (MIT), cpp_magic.h and FreeBSD-derived SHA-1 code (BSD-3-Clause). SwiftCrypto includes BoringSSL source carrying Apache-2.0 headers in the supplied version. Consult the original package notices and [bundled source headers](licenses/BUNDLED_CODE_NOTICES.md) for copyright holders and component-specific terms.

SwiftTerm's benchmark tools have separate notices, retained here conservatively. Their presence does not mean those tools ship in the iOS app. Swift PNG's example snippets have a public-domain statement separate from its library licence.

## Scope

This notice set is based on the two uploaded licence/source bundles. It is not a complete software bill of materials or a determination of which targets and sources are included in an exported app. Generated SwiftCrypto Fiat headers in the supplied bundle do not include a standalone licence; verify their upstream attribution and any additional assembly/generated-source notices before distributing a binary. Retain the applicable notices with binary distributions as well as source releases.
