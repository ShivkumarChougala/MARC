# Third-party notices

MARC includes the following open-source packages. This inventory includes all resolved packages; some are build tools, tests or platform-specific components and may not be linked into the iPhone app. Third-party code retains its own license. MARC uses local source snapshots of Citadel and swift-nio-ssh; the SSH snapshot includes an ECDSA parsing security backport. The other 12 packages retain their reviewed remote revisions. Local modification records are included below.

This product includes software developed by Niels Provos.

Remote notice texts identify their exact resolved revisions. Local snapshots identify their upstream base revisions and MARC modifications in `Vendor/DEPENDENCIES.json`. Embedded source notices are retained below along with root licenses and NOTICE files. Source comment wording is preserved; trailing whitespace is normalized in this Markdown copy. Bundled source notices remain verbatim.

## BigInt 5.7.0

Repository: https://github.com/attaswift/BigInt.git

Revision: `e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe`

### LICENSE.md

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/LICENSE.md

```text

Copyright (c) 2016-2017 Károly Lőrentey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Sources/Addition.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Addition.swift

```text
//
//  Addition.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/BigInt.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/BigInt.swift

```text
//
//  BigInt.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2015-12-27.
//  Copyright © 2016-2017 Károly Lőrentey.
//

//MARK: BigInt

/// An arbitary precision signed integer type, also known as a "big integer".
///
/// Operations on big integers never overflow, but they might take a long time to execute.
/// The amount of memory (and address space) available is the only constraint to the magnitude of these numbers.
///
/// This particular big integer type uses base-2^64 digits to represent integers.
///
/// `BigInt` is essentially a tiny wrapper that extends `BigUInt` with a sign bit and provides signed integer
/// operations. Both the underlying absolute value and the negative/positive flag are available as read-write
/// properties.
///
/// Not all algorithms of `BigUInt` are available for `BigInt` values; for example, there is no square root or
/// primality test for signed integers. When you need to call one of these, just extract the absolute value:
///
/// ```Swift
/// BigInt(255).magnitude.isPrime()   // Returns false
/// ```
///
```

### Sources/BigUInt.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/BigUInt.swift

```text
//
//  BigUInt.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2015-12-26.
//  Copyright © 2016-2017 Károly Lőrentey.
//

/// An arbitary precision unsigned integer type, also known as a "big integer".
///
/// Operations on big integers never overflow, but they may take a long time to execute.
/// The amount of memory (and address space) available is the only constraint to the magnitude of these numbers.
///
/// This particular big integer type uses base-2^64 digits to represent integers; you can think of it as a wrapper
/// around `Array<UInt64>`. (In fact, `BigUInt` only uses an array if there are more than two digits.)
```

### Sources/Bitwise Ops.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Bitwise Ops.swift

```text
//
//  Bitwise Ops.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

//MARK: Bitwise Operations
```

### Sources/Codable.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Codable.swift

```text
//
//  Codable.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2017-8-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//


// Little-endian to big-endian
```

### Sources/Comparable.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Comparable.swift

```text
//
//  Comparable.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Data Conversion.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Data Conversion.swift

```text
//
//  Data Conversion.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-04.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Division.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Division.swift

```text
//
//  Division.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

//MARK: Full-width multiplication and division

// TODO: Return to `where Magnitude == Self` when SR-13491 is resolved
```

### Sources/Exponentiation.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Exponentiation.swift

```text
//
//  Exponentiation.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Floating Point Conversion.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Floating Point Conversion.swift

```text
//
//  Floating Point Conversion.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2017-08-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/GCD.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/GCD.swift

```text
//
//  GCD.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Hashable.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Hashable.swift

```text
//
//  Hashable.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Integer Conversion.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Integer Conversion.swift

```text
//
//  Integer Conversion.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2017-08-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Multiplication.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Multiplication.swift

```text
//
//  Multiplication.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Prime Test.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Prime Test.swift

```text
//
//  Prime Test.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-04.
//  Copyright © 2016-2017 Károly Lőrentey.
//

/// The first several [prime numbers][primes].
///
/// [primes]: https://oeis.org/A000040
```

### Sources/Random.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Random.swift

```text
//
//  Random.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-04.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Shifts.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Shifts.swift

```text
//
//  Shifts.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Square Root.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Square Root.swift

```text
//
//  Square Root.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//

//MARK: Square Root
```

### Sources/Strideable.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Strideable.swift

```text
//
//  Strideable.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2017-08-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/String Conversion.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/String Conversion.swift

```text
//
//  String Conversion.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Subtraction.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Subtraction.swift

```text
//
//  Subtraction.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2016-01-03.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

### Sources/Words and Bits.swift:embedded-notice

Source: https://github.com/attaswift/BigInt/blob/e07e00fa1fd435143a2dcf8b7eec9a7710b2fdfe/Sources/Words and Bits.swift

```text
//
//  Words and Bits.swift
//  BigInt
//
//  Created by Károly Lőrentey on 2017-08-11.
//  Copyright © 2016-2017 Károly Lőrentey.
//
```

## Citadel 0.12.1 + MARC local integration

Repository: https://github.com/orlandos-nl/Citadel

Revision: `ae8562f895de06ccb86fdb1cbb65fd99c8976e12`

### LICENSE

Source: https://github.com/orlandos-nl/Citadel/blob/ae8562f895de06ccb86fdb1cbb65fd99c8976e12/LICENSE

```text
MIT License

Copyright (c) 2022 Orlandos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Sources/CCitadelBcrypt/bcrypt.c:embedded-notice

Source: https://github.com/orlandos-nl/Citadel/blob/ae8562f895de06ccb86fdb1cbb65fd99c8976e12/Sources/CCitadelBcrypt/bcrypt.c

```text
/*
 * Copyright (c) 2014 Ted Unangst <tedu@openbsd.org>
 * Copyright (c) 1997 Niels Provos <provos@umich.edu>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
```

### Sources/CCitadelBcrypt/blf.c:embedded-notice

Source: https://github.com/orlandos-nl/Citadel/blob/ae8562f895de06ccb86fdb1cbb65fd99c8976e12/Sources/CCitadelBcrypt/blf.c

```text
/*
 * Blowfish block cipher for OpenBSD
 * Copyright 1997 Niels Provos <provos@physnet.uni-hamburg.de>
 * All rights reserved.
 *
 * Implementation advice by David Mazieres <dm@lcs.mit.edu>.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *      This product includes software developed by Niels Provos.
 * 4. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
```

### Sources/CCitadelBcrypt/blf.h:embedded-notice

Source: https://github.com/orlandos-nl/Citadel/blob/ae8562f895de06ccb86fdb1cbb65fd99c8976e12/Sources/CCitadelBcrypt/blf.h

```text
/*
 * Blowfish - a fast block cipher designed by Bruce Schneier
 *
 * Copyright 1997 Niels Provos <provos@physnet.uni-hamburg.de>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *      This product includes software developed by Niels Provos.
 * 4. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
```

### Sources/Citadel/Exec/Server/ExecHandler.swift:embedded-notice

Source: https://github.com/orlandos-nl/Citadel/blob/ae8562f895de06ccb86fdb1cbb65fd99c8976e12/Sources/Citadel/Exec/Server/ExecHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CitadelServerExample/EchoShell/BasicCommands.swift:embedded-notice

Source: https://github.com/orlandos-nl/Citadel/blob/ae8562f895de06ccb86fdb1cbb65fd99c8976e12/Sources/CitadelServerExample/EchoShell/BasicCommands.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Citadel open source and the ClamShell project
//
// Copyright (c) 2023 Gregor Feigel and the Citadel project authors
// Licensed under MIT License
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: MIT
//
//===----------------------------------------------------------------------===//
```

### MARC local modifications

Source: Vendor/Citadel/MARC_MODIFICATIONS.md

```text
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
```

## h 1.0.1

Repository: https://github.com/rarestype/h

Revision: `aa3626829160917d4378330617971977cbd78f5b`

### LICENSE

Source: https://github.com/rarestype/h/blob/aa3626829160917d4378330617971977cbd78f5b/LICENSE

```text

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright 2026
   Diana Ma (@tayloraswift)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

### NOTICE

Source: https://github.com/rarestype/h/blob/aa3626829160917d4378330617971977cbd78f5b/NOTICE

```text
the `h` package was created by diana ma (@tayloraswift).

you are welcome to contribute to this project at:

    https://github.com/rarestype/h

we do not maintain any other mirrors of this repository, and such
forks of this repository may not carry the most up-to-date code.
```

## swift-argument-parser 1.8.2

Repository: https://github.com/apple/swift-argument-parser

Revision: `6a52f3251125d74daf04fcbd5e6f08a75d074382`

### LICENSE.txt

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/LICENSE.txt

```text
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

    1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

    2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

    3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

    4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

    5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

    6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

    7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

    8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

    9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

    END OF TERMS AND CONDITIONS

    APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

    Copyright [yyyy] [name of copyright owner]

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.



## Runtime Library Exception to the Apache 2.0 License: ##


    As an exception, if you use this Software to compile your source code and
    portions of this Software are embedded into the binary product as a result,
    you may redistribute such product without providing attribution as would
    otherwise be required by Sections 4(a), 4(b) and 4(d) of the License.
```

### Sources/ArgumentParser/Completions/BashCompletionsGenerator.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Completions/BashCompletionsGenerator.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//
```

### Sources/ArgumentParser/Parsable Properties/Argument.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/Argument.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A property wrapper that represents a positional command-line argument.
///
/// Use the `@Argument` wrapper to define a property of your custom command as
/// a positional argument. A *positional argument* for a command-line tool is
/// specified without a label and must appear in declaration order. `@Argument`
/// properties with `Optional` type or a default value are optional for the user
/// of your command-line tool.
///
/// For example, the following program has two positional arguments. The `name`
/// argument is required, while `greeting` is optional because it has a default
/// value.
///
/// ```swift
/// @main
/// struct Greet: ParsableCommand {
///     @Argument var name: String
///     @Argument var greeting: String = "Hello"
///
///     mutating func run() {
///         print("\(greeting) \(name)!")
///     }
/// }
/// ```
///
/// You can call this program with just a name or with a name and a
/// greeting. When you supply both arguments, the first argument is always
/// treated as the name, due to the order of the property declarations.
///
///     $ greet Nadia
///     Hello Nadia!
///     $ greet Tamara Hi
///     Hi Tamara!
```

### Sources/ArgumentParser/Parsable Properties/ArgumentDiscussion.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/ArgumentDiscussion.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A structure that contains an extended description of the argument.
///
/// For `EnumerableOptionValue` types, the `.enumerated` case encapsulates the
/// necessary information to list each of the possible values and their
/// descriptions. Optionally, users can add a discussion preamble that will be
/// appended to the beginning of the value list section.
///
/// For example, the following `EnumerableOptionValue` type defined in a command
/// could contain an additional discussion block defined in its `ArgumentHelp`:
///
/// ```swift
/// enum Color: String, EnumerableOptionValue {
///   case red
///   case blue
///   case yellow
///
///   public var description: String {
///     switch self {
///        case .red:
///         return "A red color."
///        case. blue:
///         return "A blue color."
///        case .yellow:
///         return "A yellow color."
///     }
///   }
/// }
///
/// struct Example: ParsableCommand {
///   @Option(help: ArgumentHelp(discussion: "A set of available colors."))
///   var color: Color
/// }
/// ```
///
/// To which the printed usage would look like the following:
///
/// ```
/// USAGE: example --color <color>
///
/// OPTIONS:
///    --color <color>
///         A set of available colors.
///         Values:
///           red           - A red color.
///           blue          - A blue color.
///           yellow        - A yellow color.
///    -h, --help           Show help information
/// ```
///
/// Without the additional discussion text:
///
/// ```swift
/// @Option var color: Color
/// ```
///
/// The printed usage would look like the following:
///
/// ```
/// USAGE: example --color <color>
///
/// OPTIONS:
///    --color <color>
///          red           - A red color.
///          blue          - A blue color.
///          yellow        - A yellow color.
///    -h, --help           Show help information
/// ```
///
/// Arrays of enumerable types are also supported and will display the same
/// enumerated format:
///
/// ```swift
/// @Option var colors: [Color] = [.red, .blue]
/// ```
///
/// The printed usage would look like the following:
///
/// ```
/// USAGE: example [--colors <colors> ...]
///
/// OPTIONS:
///    --colors <colors>        (default: red, blue)
///          red           - A red color.
///          blue          - A blue color.
///          yellow        - A yellow color.
///    -h, --help           Show help information
/// ```
///
/// In any case where the argument type is not `EnumerableOptionValue` or an
/// array of `EnumerableOptionValue`, the default implementation will use the
/// `.staticText` case and will print a block of discussion text.
```

### Sources/ArgumentParser/Parsable Properties/ArgumentHelp.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/ArgumentHelp.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Help information for a command-line argument.
```

### Sources/ArgumentParser/Parsable Properties/ArgumentVisibility.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/ArgumentVisibility.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Visibility level of an argument's help.
```

### Sources/ArgumentParser/Parsable Properties/CompletionKind.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/CompletionKind.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// The type of completion to use for an argument or option value.
///
/// For all `CompletionKind`s, the completion shell script is configured with
/// the following settings, which will not affect the requesting shell outside
/// the completion script:
///
/// ### bash
///
/// ```shell
/// shopt -s extglob
/// set +o history +o posix
/// ```
///
/// ### fish
///
/// no settings
///
/// ### zsh
///
/// ```shell
/// emulate -RL zsh -G
/// setopt extendedglob nullglob numericglobsort
/// unsetopt aliases banghist
/// ```
```

### Sources/ArgumentParser/Parsable Properties/Errors.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/Errors.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// An error type that is presented to the user as an error with parsing their
/// command-line input.
```

### Sources/ArgumentParser/Parsable Properties/Flag.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/Flag.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A property wrapper that represents a command-line flag.
///
/// Use the `@Flag` wrapper to define a property of your custom type as a
/// command-line flag. A *flag* is a dash-prefixed label that can be provided on
/// the command line, such as `-d` and `--debug`.
///
/// For example, the following program declares a flag that lets a user indicate
/// that seconds should be included when printing the time.
///
/// ```swift
/// @main
/// struct Time: ParsableCommand {
///     @Flag var includeSeconds = false
///
///     mutating func run() {
///         if includeSeconds {
///             print(Date.now.formatted(.dateTime.hour().minute().second()))
///         } else {
///             print(Date.now.formatted(.dateTime.hour().minute()))
///         }
///     }
/// }
/// ```
///
/// `includeSeconds` has a default value of `false`, but becomes `true` if
/// `--include-seconds` is provided on the command line.
///
///     $ time
///     11:09 AM
///     $ time --include-seconds
///     11:09:15 AM
///
/// A flag can have a value that is a `Bool`, an `Int`, or any `EnumerableFlag`
/// type. When using an `EnumerableFlag` type as a flag, the individual cases
/// form the flags that are used on the command line.
///
///     @main
///     struct Math: ParsableCommand {
///         enum Operation: EnumerableFlag {
///             case add
///             case multiply
///         }
///
///         @Flag var operation: Operation
///
///         mutating func run() {
///             print("Time to \(operation)!")
///         }
///     }
///
/// Instead of using the name of the `operation` property as the flag in this
/// case, the two cases of the `Operation` enumeration become valid flags.
/// The `operation` property is neither optional nor given a default value, so
/// one of the two flags is required.
///
///     $ math --add
///     Time to add!
///     $ math
///     Error: Missing one of: '--add', '--multiply'
```

### Sources/ArgumentParser/Parsable Properties/NameSpecification.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/NameSpecification.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A specification for how to represent a property as a command-line argument
/// label.
///
/// You can specify the names for an option or flag by using either string literal
/// syntax or using one or more of the `NameSpecification` members. For
/// example, to specify that the `verbose` property should have the names
/// `-v` and `--verbose`, all of the following declarations are equivalent:
///
/// ```
/// @Flag(name: "-v --verbose")
/// var verbose = false
///
/// @Flag(name: .shortAndLong)
/// var verbose = false
///
/// @Flag(name: [.short, .long])
/// var verbose = false
///
/// @Flag(name: ["-v", .long])
/// var verbose = false
/// ```
```

### Sources/ArgumentParser/Parsable Properties/Option.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/Option.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A property wrapper that represents a command-line option.
///
/// Use the `@Option` wrapper to define a property of your custom command as a
/// command-line option. An *option* is a named value passed to a command-line
/// tool, like `--configuration debug`. Options can be specified in any order.
///
/// An option can have a default value specified as part of its
/// declaration; options with optional `Value` types implicitly have `nil` as
/// their default value. Options that are neither declared as `Optional` nor
/// given a default value are required for users of your command-line tool.
///
/// For example, the following program defines three options:
///
/// ```swift
/// @main
/// struct Greet: ParsableCommand {
///     @Option var greeting = "Hello"
///     @Option var age: Int? = nil
///     @Option var name: String
///
///     mutating func run() {
///         print("\(greeting) \(name)!")
///         if let age {
///             print("Congrats on making it to the ripe old age of \(age)!")
///         }
///     }
/// }
/// ```
///
/// `greeting` has a default value of `"Hello"`, which can be overridden by
/// providing a different string as an argument, while `age` defaults to `nil`.
/// `name` is a required option because it is non-`nil` and has no default
/// value.
///
///     $ greet --name Alicia
///     Hello Alicia!
///     $ greet --age 28 --name Seungchin --greeting Hi
///     Hi Seungchin!
///     Congrats on making it to the ripe old age of 28!
```

### Sources/ArgumentParser/Parsable Properties/OptionGroup.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/OptionGroup.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A wrapper that transparently includes a parsable type.
///
/// Use an option group to include a group of options, flags, or arguments
/// declared in a parsable type.
///
/// ```swift
/// struct GlobalOptions: ParsableArguments {
///     @Flag(name: .shortAndLong)
///     var verbose: Bool = false
///
///     @Argument var values: [Int]
/// }
///
/// struct Options: ParsableArguments {
///     @Option var name: String
///     @OptionGroup var globals: GlobalOptions
/// }
/// ```
///
/// The flag and positional arguments declared as part of `GlobalOptions` are
/// included when parsing `Options`.
```

### Sources/ArgumentParser/Parsable Properties/ParentCommand.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Properties/ParentCommand.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A wrapper that adds a reference to a parent command.
///
/// Use the `@ParentCommand` wrapper to gain access to a parent command's state.
///
/// The arguments, options, and flags in a `@ParentCommand` type are omitted from
/// the help screen for the including child command, and only appear in the parent's
/// help screen. To include the help in both screens, use the ``OptionGroup``
/// wrapper instead.
///
///
/// ```swift
/// struct SuperCommand: ParsableCommand {
///     static let configuration = CommandConfiguration(
///         subcommands: [SubCommand.self]
///     )
///
///     @Flag(name: .shortAndLong)
///     var verbose: Bool = false
/// }
///
/// struct SubCommand: ParsableCommand {
///     @ParentCommand var parent: SuperCommand
///
///     mutating func run() throws {
///         if self.parent.verbose {
///             print("Verbose")
///         }
///     }
/// }
/// ```
```

### Sources/ArgumentParser/Parsable Types/AsyncParsableCommand.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Types/AsyncParsableCommand.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A type that can be executed asynchronously, as part of a nested tree of
/// commands.
```

### Sources/ArgumentParser/Parsable Types/CommandConfiguration.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Types/CommandConfiguration.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// The configuration for a command.
```

### Sources/ArgumentParser/Parsable Types/CommandGroup.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Types/CommandGroup.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A set of commands grouped together under a common name.
```

### Sources/ArgumentParser/Parsable Types/EnumerableFlag.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Types/EnumerableFlag.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A type that represents the different possible flags to be used by a
/// `@Flag` property.
///
/// For example, the `Size` enumeration declared here can be used as the type of
/// a `@Flag` property:
///
/// ```swift
/// enum Size: String, EnumerableFlag {
///     case small, medium, large, extraLarge
/// }
///
/// struct Example: ParsableCommand {
///     @Flag var sizes: [Size]
///
///     mutating func run() {
///         print(sizes)
///     }
/// }
/// ```
///
/// By default, each case name is converted to a flag by using the `.long` name
/// specification, so a user can call `example` like this:
///
///     $ example --small --large
///     [.small, .large]
///
/// Provide alternative or additional name specifications for each case by
/// implementing the `name(for:)` static method on your `EnumerableFlag` type.
///
/// ```swift
/// extension Size {
///     static func name(for value: Self) -> NameSpecification {
///         switch value {
///         case .extraLarge:
///             return [.customShort("x"), .long]
///         default:
///             return .shortAndLong
///         }
///     }
/// }
/// ```
///
/// With this extension, a user can use short or long versions of the flags:
///
///     $ example -s -l -x --medium
///     [.small, .large, .extraLarge, .medium]
```

### Sources/ArgumentParser/Parsable Types/ExpressibleByArgument.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Types/ExpressibleByArgument.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A type that can be expressed as a command-line argument.
```

### Sources/ArgumentParser/Parsable Types/ParsableArguments.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Types/ParsableArguments.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A type that can be parsed from a program's command-line arguments.
///
/// When you implement a `ParsableArguments` type, all properties must be declared with
/// one of the four property wrappers provided by the `ArgumentParser` library.
```

### Sources/ArgumentParser/Parsable Types/ParsableCommand.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsable Types/ParsableCommand.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A type that can be executed as part of a nested tree of commands.
```

### Sources/ArgumentParser/Parsing/ArgumentDecoder.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsing/ArgumentDecoder.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A previously decoded parsable arguments type.
///
/// Because arguments are consumed and decoded the first time they're
/// encountered, we save the decoded instances for using later in the
/// command/subcommand hierarchy.
```

### Sources/ArgumentParser/Parsing/ArgumentSet.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsing/ArgumentSet.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A nested tree of argument definitions.
///
/// The main reason for having a nested representation is to build help output.
/// For output like:
///
///     Usage: mytool [-v | -f] <input> <output>
///
/// The `-v | -f` part is one *set* that’s optional, `<input> <output>` is
/// another. Both of these can then be combined into a third set.
```

### Sources/ArgumentParser/Parsing/InputKey.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsing/InputKey.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Represents the path to a parsed field, annotated with ``Flag``, ``Option``
/// or ``Argument``.
///
/// Fields that are directly declared on a ``ParsableCommand`` have a path of
/// length 1, while fields that are declared indirectly (and included via an
/// option group) have longer paths.
```

### Sources/ArgumentParser/Parsing/InputOrigin.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsing/InputOrigin.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Specifies where a given input came from.
///
/// When reading from the command line, a value might originate from a single
/// index, multiple indices, or from part of an index. For this command:
///
///     struct Example: ParsableCommand {
///         @Flag(name: .short) var verbose = false
///         @Flag(name: .short) var expert = false
///
///         @Option var count: Int
///     }
///
/// ...with this usage:
///
///     $ example -ve --count 5
///
/// The parsed value for the `count` property will come from indices `1` and
/// `2`, while the value for `verbose` will come from index `1`, sub-index `0`.
```

### Sources/ArgumentParser/Parsing/ParsedValues.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsing/ParsedValues.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// The resulting values after parsing the command-line arguments.
///
/// This is a flat key-value list of values.
```

### Sources/ArgumentParser/Parsing/ParserError.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsing/ParserError.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Gets thrown while parsing and will be handled by the error output generation.
```

### Sources/ArgumentParser/Parsing/SplitArguments.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Parsing/SplitArguments.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A single `-f`, `--foo`, or `--foo=bar`.
///
/// When parsing, we might see `"--foo"` or `"--foo=bar"`.
```

### Sources/ArgumentParser/Utilities/CollectionExtensions.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Utilities/CollectionExtensions.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//
```

### Sources/ArgumentParser/Utilities/Foundation.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Utilities/Foundation.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//
```

### Sources/ArgumentParser/Validators/AsyncCompletionsValidator.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Validators/AsyncCompletionsValidator.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A validator that ensures async custom completion functions are used only for
/// `AsyncParsableCommand`s.
```

### Sources/ArgumentParser/Validators/CodingKeyValidator.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Validators/CodingKeyValidator.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A validator that ensures that all arguments have corresponding coding keys.
```

### Sources/ArgumentParser/Validators/NonsenseFlagsValidator.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Validators/NonsenseFlagsValidator.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A validator that prevents declaring flags that can't be turned off.
```

### Sources/ArgumentParser/Validators/PositionalArgumentsValidator.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Validators/PositionalArgumentsValidator.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A validator for positional argument arrays.
///
/// For positional arguments to be valid, there must be at most one
/// positional array argument, and it must be the last positional argument
/// in the argument list. Any other configuration leads to ambiguity in
/// parsing the arguments.
```

### Sources/ArgumentParser/Validators/UniqueNamesValidator.swift:embedded-notice

Source: https://github.com/apple/swift-argument-parser/blob/6a52f3251125d74daf04fcbd5e6f08a75d074382/Sources/ArgumentParser/Validators/UniqueNamesValidator.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A validator that ensures argument names are unique within a
/// `ParsableArguments` or `ParsableCommand`.
```

## swift-asn1 1.7.3

Repository: https://github.com/apple/swift-asn1.git

Revision: `3b6410f7dee09eb33cdd26260c5fd47fda19b0e2`

### LICENSE.txt

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/LICENSE.txt

```text

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

### NOTICE.txt

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/NOTICE.txt

```text

                            The SwiftASN1 Project
                            =====================

Please visit the SwiftASN1 web site for more information:

  * https://github.com/apple/swift-asn1

Copyright 2022 The SwiftASN1 Project

The SwiftASN1 Project licenses this file to you under the Apache License,
version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at:

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.

Also, please refer to each LICENSE.txt file, which is located in
the 'license' directory of the distribution file, for the license terms of the
components that this product depends on.

---

This product contains derivations of various scripts from SwiftNIO.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/apple/swift-nio

---

This product contains derivations of various scripts from Swift OpenAPI Generator.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/apple/swift-openapi-generator
```

### Sources/SwiftASN1/ASN1.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/ASN1.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/SwiftASN1/BER.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/BER.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2023 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// ``BER`` defines a namespace that is used to store a number of helper methods and types
/// for BER encoding and decoding.
```

### Sources/SwiftASN1/Basic ASN1 Types/ASN1Any.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ASN1Any.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// An ASN1 ANY represents...well, anything.
///
/// In this case we store the ASN.1 ANY as a serialized representation. This is a bit limiting,
/// but it's the only safe way to manage this data, as we cannot arbitrarily parse it.
///
/// The only things users can do with ASN.1 ANYs is to try to decode them as something else,
/// to create them from something else, or to serialize them.
```

### Sources/SwiftASN1/Basic ASN1 Types/ASN1BitString.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ASN1BitString.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A bitstring is a representation of a sequence of bits.
///
/// In ASN.1, bitstrings serve two different use-cases. The first is as arbitrary-length sequences of bits.
/// These are typically used to encode cryptographic keys, such as RSA keys. The second is as a form of bitset.
///
/// In the case of a bitset, DER has additional requirements as to how to represent the object. This type does not
/// enforce those additional rules: users are expected to implement that validation themselves.
```

### Sources/SwiftASN1/Basic ASN1 Types/ASN1Boolean.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ASN1Boolean.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/SwiftASN1/Basic ASN1 Types/ASN1Identifier.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ASN1Identifier.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// An ``ASN1Identifier`` is a representation of the abstract notion of an ASN.1 identifier.
```

### Sources/SwiftASN1/Basic ASN1 Types/ASN1Integer.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ASN1Integer.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A protocol that represents any internal object that can present itself as an INTEGER, or be parsed from
/// an INTEGER.
///
/// This protocol exists to allow users to handle the possibility of decoding integers that cannot fit into
/// UInt64 or Int64. While both of those types conform by default, users can conform their preferred
/// arbitrary-width integer type as well, or use `ArraySlice<UInt8>` to store the raw bytes of the
/// integer directly.
```

### Sources/SwiftASN1/Basic ASN1 Types/ASN1Null.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ASN1Null.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// An ASN1 NULL represents nothing.
```

### Sources/SwiftASN1/Basic ASN1 Types/ASN1OctetString.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ASN1OctetString.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// An OCTET STRING is a representation of a string of octets.
```

### Sources/SwiftASN1/Basic ASN1 Types/ASN1Strings.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ASN1Strings.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A UTF8String represents a string made up of UTF-8 bytes.
```

### Sources/SwiftASN1/Basic ASN1 Types/ArraySliceBigint.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ArraySliceBigint.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// For temporary purposes we pretend that ArraySlice is our "bigint" type. We don't really need anything else.
```

### Sources/SwiftASN1/Basic ASN1 Types/GeneralizedTime.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/GeneralizedTime.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// GeneralizedTime represents a date and time.
///
/// In DER format, this is always in the form of `YYYYMMDDHHMMSSZ`. The type in
/// general is capable of expressing fractional seconds. The time is always in the
/// UTC time zone.
///
/// In BER format, seconds may be omitted, and timezone offsets can be present.
```

### Sources/SwiftASN1/Basic ASN1 Types/ObjectIdentifier.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/ObjectIdentifier.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// An Object Identifier is a representation of some kind of object.
///
/// It represents a node in an OID hierarchy, and is usually represented as an ordered sequence of numbers. Object identifiers
/// form a nested tree of namespaces.
///
/// The most common way to construct an OID is to create one using an array literal. For example, the OID 2.5.4.41 can be created
/// as:
///
/// ```swift
/// let name: ASN1ObjectIdentifier = [2, 5, 4, 41]
/// ```
///
/// This object also has a number of pre-existing values defined in namespaces. Users are encouraged to create their own namespaces to
/// make it easier to use OIDs in their own serialization code.
```

### Sources/SwiftASN1/Basic ASN1 Types/TimeUtilities.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/TimeUtilities.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2022 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/SwiftASN1/Basic ASN1 Types/UTCTime.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Basic ASN1 Types/UTCTime.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2022 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// UTCTime represents a date and time.
///
/// In DER format, this is always in the form of `YYMMDDHHMMSSZ`, with no support for fractional seconds.
/// The time is always in the UTC time zone.
///
/// ``UTCTime`` differs from ``GeneralizedTime`` in that it only has support for a two-digit year. This
/// means that it can only encode dates between 1950 and 2049. For dates outside that range, prefer
/// ``GeneralizedTime``.
```

### Sources/SwiftASN1/DER.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/DER.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// ``DER`` defines a namespace that is used to store a number of helper methods and types
/// for DER encoding and decoding.
```

### Sources/SwiftASN1/Errors.swift:embedded-notice

Source: https://github.com/apple/swift-asn1/blob/3b6410f7dee09eb33cdd26260c5fd47fda19b0e2/Sources/SwiftASN1/Errors.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Represents an error that may be thrown from the ``SwiftASN1`` module.
///
/// This object contains both an error ``code`` and a textual reason for the error,
/// as well as source code context for the error. When attempting to process a specific
/// error, users are encouraged to check the ``code``. The additional diagnostic information
/// is available by using `String(describing:)` to format ``ASN1Error``.
///
/// This type is `Equatable` and `Hashable`, but only the ``code`` field is considered in the
/// implementation of that behaviour. This makes it relatively easy to test code that throws
/// a specific error by creating the error type directly in your own code.
```

## swift-atomics 1.3.1

Repository: https://github.com/apple/swift-atomics.git

Revision: `0442cb5a3f98ab802acb777929fdb446bda11a34`

### LICENSE.txt

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/LICENSE.txt

```text
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

    1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

    2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

    3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

    4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

    5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

    6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

    7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

    8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

    9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

    END OF TERMS AND CONDITIONS

    APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

    Copyright [yyyy] [name of copyright owner]

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.



## Runtime Library Exception to the Apache 2.0 License: ##


    As an exception, if you use this Software to compile your source code and
    portions of this Software are embedded into the binary product as a result,
    you may redistribute such product without providing attribution as would
    otherwise be required by Sections 4(a), 4(b) and 4(d) of the License.
```

### Sources/Atomics/Conformances/OptionalRawRepresentable.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Conformances/OptionalRawRepresentable.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2021 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
```

### Sources/Atomics/Conformances/RawRepresentable.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Conformances/RawRepresentable.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
```

### Sources/Atomics/Conformances/autogenerated/AtomicBool.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Conformances/autogenerated/AtomicBool.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//


// #############################################################################
// #                                                                           #
// #            DO NOT EDIT THIS FILE; IT IS AUTOGENERATED.                    #
// #                                                                           #
// #############################################################################
```

### Sources/Atomics/Conformances/autogenerated/IntegerConformances.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Conformances/autogenerated/IntegerConformances.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// #############################################################################
// #                                                                           #
// #            DO NOT EDIT THIS FILE; IT IS AUTOGENERATED.                    #
// #                                                                           #
// #############################################################################
```

### Sources/Atomics/Primitives/autogenerated/Primitives.native.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Primitives/autogenerated/Primitives.native.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//


// #############################################################################
// #                                                                           #
// #            DO NOT EDIT THIS FILE; IT IS AUTOGENERATED.                    #
// #                                                                           #
// #############################################################################
```

### Sources/Atomics/Protocols/AtomicInteger.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Protocols/AtomicInteger.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A type that supports atomic integer operations through a separate
/// atomic storage representation.
///
/// Atomic integer types provide a number of additional atomic
/// operations beyond the ones supported by `AtomicValue`, such as
/// atomic increments/decrements as well as atomic bitwise operations.
/// These may be mapped to dedicated instructions that can be more
/// efficient than implementations based on the general compare and
/// exchange operation; however, this depends on the capabilities of
/// the compiler and the underlying hardware.
```

### Sources/Atomics/Protocols/AtomicOptionalWrappable.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Protocols/AtomicOptionalWrappable.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// An atomic value that also supports atomic operations when wrapped
/// in an `Optional`. Atomic optional wrappable types come with a
/// standalone atomic representation for their optional-wrapped
/// variants.
```

### Sources/Atomics/Protocols/AtomicReference.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Protocols/AtomicReference.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A class type that supports atomic strong references.
///
///     class MyObject: AtomicReference {}
///
///     let object = MyObject()
///     let ref = ManagedAtomic<MyObject>(object)
///
///     ref.load(ordering: .relaxed) // Returns `object`.
///
/// The conforming class is allowed to be non-final, but `ManagedAtomic` and
/// `UnsafeAtomic` do not support using a subclass as their generic argument --
/// the type of an atomic reference must be precisely the same class that
/// originally conformed to the protocol.
///
///
///     class Derived: MyObject {}
///
///     let ref2: ManagedAtomic<Derived>
///     // error: 'ManagedAtomic' requires the types 'Derived' and 'Base' be equivalent
///
/// Note that this limitation only affects the static type of the
/// `ManagedAtomic`/`UnsafeAtomic` variables. Such references still fully
/// support holding instances of subclasses of the conforming class. (Returned
/// may be downcasted from the base type after an `is` check.)
///
///     let child = Derived()
///     ref.store(child, ordering: .relaxed) // OK!
///     let value = ref.load(ordering: .relaxed)
///     // `value` is a variable of type `MyObject`, holding a `Derived` instance.
///     print(value is Derived) // Prints "true"
///
```

### Sources/Atomics/Protocols/AtomicStorage.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Protocols/AtomicStorage.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// The storage representation for an atomic value, providing pointer-based
/// atomic operations. This is a low-level implementation detail of atomic
/// types; instead of directly handling conforming types, it is usually better
/// to use the `UnsafeAtomic` or `ManagedAtomic` generics -- these provide more
/// convenient and safer interfaces while also ensuring that the storage is
/// correctly constructed and destroyed.
///
/// Logically, atomic storage representations are neither value- nor reference
/// types: they should be treated as non-copiable values with a custom
/// destructor. Such constructs cannot currently be modeled directly in Swift,
/// so types conforming to this protocol must be handled carefully to prevent
/// accidental copying. For example, it usually isn't safe to pass around atomic
/// storage representations as function arguments or return values. Instead,
/// they are usually addressed through unsafe pointers.
```

### Sources/Atomics/Protocols/AtomicValue.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Protocols/AtomicValue.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A type that supports atomic operations through a separate atomic storage
/// representation.
```

### Sources/Atomics/Types/AtomicMemoryOrderings.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Types/AtomicMemoryOrderings.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// Specifies the memory ordering semantics of an atomic load operation.
```

### Sources/Atomics/Types/DoubleWord.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Types/DoubleWord.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
```

### Sources/Atomics/Types/ManagedAtomic.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Types/ManagedAtomic.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A reference type holding an atomic value, with automatic memory management.
```

### Sources/Atomics/Types/ManagedAtomicLazyReference.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Types/ManagedAtomicLazyReference.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A reference type holding a lazily initializable atomic
/// strong reference, with automatic memory management.
///
/// These values can be set (initialized) exactly once, but read many
/// times.
```

### Sources/Atomics/Types/UnsafeAtomic.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Types/UnsafeAtomic.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// An unsafe reference type holding an atomic value, requiring manual memory
/// management of the underlying storage representation.
```

### Sources/Atomics/Types/UnsafeAtomicLazyReference.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Types/UnsafeAtomicLazyReference.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// An unsafe reference type holding a lazily initializable atomic
/// strong reference, requiring manual memory management of the
/// underlying storage representation.
///
/// These values can be set (initialized) exactly once, but read many
/// times.
```

### Sources/Atomics/Types/autogenerated/IntegerOperations.swift:embedded-notice

Source: https://github.com/apple/swift-atomics/blob/0442cb5a3f98ab802acb777929fdb446bda11a34/Sources/Atomics/Types/autogenerated/IntegerOperations.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// #############################################################################
// #                                                                           #
// #            DO NOT EDIT THIS FILE; IT IS AUTOGENERATED.                    #
// #                                                                           #
// #############################################################################
```

## swift-collections 1.7.2

Repository: https://github.com/apple/swift-collections.git

Revision: `3b69cedbaa49957e97c092ae400bb57602ef941f`

### LICENSE.txt

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/LICENSE.txt

```text
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

    1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

    2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

    3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

    4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

    5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

    6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

    7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

    8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

    9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

    END OF TERMS AND CONDITIONS

    APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

    Copyright [yyyy] [name of copyright owner]

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.



## Runtime Library Exception to the Apache 2.0 License: ##


    As an exception, if you use this Software to compile your source code and
    portions of this Software are embedded into the binary product as a result,
    you may redistribute such product without providing attribution as would
    otherwise be required by Sections 4(a), 4(b) and 4(d) of the License.
```

### Sources/BasicContainers/HashTable/_HTable+Bitmap.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/BasicContainers/HashTable/_HTable+Bitmap.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//
```

### Sources/BasicContainers/HashTable/_HTable+Bucket.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/BasicContainers/HashTable/_HTable+Bucket.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//
```

### Sources/BasicContainers/RigidArray/RigidArray+Append.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/BasicContainers/RigidArray/RigidArray+Append.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//
```

### Sources/BasicContainers/RigidArray/RigidArray+Descriptions.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/BasicContainers/RigidArray/RigidArray+Descriptions.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// FIXME: Add this when/if SE-0499 gets implemented.
//#if compiler(>=6.x)
//@available(SwiftStdlib 5.0, *)
//extension RigidArray: CustomStringConvertible where Element: ~Copyable {
//}
//#endif
```

### Sources/BasicContainers/RigidArray/RigidArray+Formatter.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/BasicContainers/RigidArray/RigidArray+Formatter.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// Generated with: ./Utils/Debugger/generate_formatters.sh
```

### Sources/BasicContainers/RigidArray/RigidArray+Iterable.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/BasicContainers/RigidArray/RigidArray+Iterable.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//
```

### Sources/BitCollections/BitArray/BitArray+Codable.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/BitCollections/BitArray/BitArray+Codable.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//
```

### Sources/BitCollections/BitArray/BitArray+ExpressibleByStringLiteral.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/BitCollections/BitArray/BitArray+ExpressibleByStringLiteral.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//
```

### Sources/DequeModule/Deque/Deque.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/DequeModule/Deque/Deque.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A collection implementing a double-ended queue. `Deque` (pronounced "deck")
/// implements an ordered random-access collection that supports efficient
/// insertions and removals from both ends.
///
///     var colors: Deque = ["red", "yellow", "blue"]
///
/// Deques implement the same indexing semantics as arrays: they use integer
/// indices, and the first element of a nonempty deque is always at index zero.
/// Like arrays, deques conform to `RangeReplaceableCollection`,
/// `MutableCollection` and `RandomAccessCollection`, providing a familiar
/// interface for manipulating their contents:
///
///     print(colors[1]) // "yellow"
///     print(colors[3]) // Runtime error: Index out of range
///
///     colors.insert("green", at: 1)
///     // ["red", "green", "yellow", "blue"]
///
///     colors.remove(at: 2) // "yellow"
///     // ["red", "green", "blue"]
///
/// Like all variable-size collections on the standard library, `Deque`
/// implements value semantics: each deque has an independent value that
/// includes the values of its elements. Modifying one deque does not affect any
/// others:
///
///     var copy = deque
///     copy[1] = "violet"
///     print(copy)  // ["red", "violet", "blue"]
///     print(deque) // ["red", "green", "blue"]
///
/// This is implemented with the copy-on-write optimization. Multiple copies of
/// a deque share the same underlying storage until you modify one of the
/// copies. When that happens, the deque being modified replaces its storage
/// with a uniquely owned copy of itself, which is then modified in place.
///
/// `Deque` stores its elements in a circular buffer, which allows efficient
/// insertions and removals at both ends of the collection; however, this comes
/// at the cost of potentially discontiguous storage. In contrast, `Array` is
/// (usually) backed by a contiguous buffer, where new data can be efficiently
/// appended to the end, but inserting at the front is relatively slow, as
/// existing elements need to be shifted to make room.
///
/// This difference in implementation means that while the interface of a deque
/// is very similar to an array, the operations have different performance
/// characteristics. Mutations near the front are expected to be significantly
/// faster in deques, but arrays may measure slightly faster for general
/// random-access lookups.
///
/// Deques provide a handful of additional operations that make it easier to
/// insert and remove elements at the front. This includes queue operations such
/// as `popFirst` and `prepend`, including the ability to directly prepend a
/// sequence of elements:
///
///     colors.append("green")
///     colors.prepend("orange")
///     // colors: ["orange", "red", "blue", "yellow", "green"]
///
///     colors.popLast() // "green"
///     colors.popFirst() // "orange"
///     // colors: ["red", "blue", "yellow"]
///
///     colors.prepend(contentsOf: ["purple", "teal"])
///     // colors: ["purple", "teal", "red", "blue", "yellow"]
///
/// Unlike arrays, deques do not currently provide direct unsafe access to their
/// underlying storage. They also lack a `capacity` property -- the size of the
/// storage buffer at any given point is an unstable implementation detail that
/// should not affect application logic. (However, deques do provide a
/// `reserveCapacity` method.)
```

### Sources/HashTreeCollections/HashNode/_AncestorHashSlots.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_AncestorHashSlots.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A collection of slot values logically addressing a particular node in a
/// hash tree. The collection is (logically) extended with zero slots up to
/// the maximum depth of the tree -- to unambiguously address a single node,
/// this therefore needs to be augmented with a `_HashLevel` value.
///
/// This construct can only be used to identify a particular node in the tree;
/// it does not necessarily have room to include an item offset in the addressed
/// node. (See `_Path` if you need to address a particular item.)
```

### Sources/HashTreeCollections/HashNode/_Bucket.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_Bucket.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// Identifies an entry in the hash table inside a node.
/// (Internally, a number between 0 and 31.)
```

### Sources/HashTreeCollections/HashNode/_Hash.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_Hash.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// An abstract representation of a hash value.
```

### Sources/HashTreeCollections/HashNode/_HashLevel.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashLevel.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// Identifies a particular level within the hash tree.
///
/// Hash trees have a maximum depth of ⎡`UInt.bitWidth / _Bucket.bitWidth`⎤, so
/// the level always fits in an `UInt8` value.
```

### Sources/HashTreeCollections/HashNode/_HashNode+Lookups.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashNode+Lookups.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// MARK: Node-level lookup operations
```

### Sources/HashTreeCollections/HashNode/_HashNode+Primitive Insertions.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashNode+Primitive Insertions.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// MARK: Node-level insertion operations
```

### Sources/HashTreeCollections/HashNode/_HashNode+Primitive Removals.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashNode+Primitive Removals.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// MARK: Node-level removal operations
```

### Sources/HashTreeCollections/HashNode/_HashNode+Structural isEqualSet.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashNode+Structural isEqualSet.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// TODO: `Equatable` needs more test coverage, apart from hash-collision smoke test
```

### Sources/HashTreeCollections/HashNode/_HashNode+Subtree Modify.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashNode+Subtree Modify.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// MARK: Subtree-level in-place mutation operations
```

### Sources/HashTreeCollections/HashNode/_HashNode+Subtree Removals.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashNode+Subtree Removals.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// MARK: Subtree-level removal operations
```

### Sources/HashTreeCollections/HashNode/_HashNode.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashNode.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A node in the hash tree, logically representing a hash table with
/// 32 buckets, corresponding to a 5-bit slice of a full hash value.
///
/// Each bucket may store either a single key-value pair or a reference
/// to a child node that contains additional items.
///
/// To save space, children and items are stored compressed into the two
/// ends of a single raw storage buffer, with the free space in between
/// available for use by either side.
///
/// The storage is arranged as shown below.
///
///     ┌───┬───┬───┬───┬───┬──────────────────┬───┬───┬───┬───┐
///     │ 0 │ 1 │ 2 │ 3 │ 4 │→   free space   ←│ 3 │ 2 │ 1 │ 0 │
///     └───┴───┴───┴───┴───┴──────────────────┴───┴───┴───┴───┘
///      children                                         items
///
/// Note that the region for items grows downwards from the end, so the item
/// at slot 0 is at the very end of the buffer.
///
/// Two 32-bit bitmaps are used to associate each child and item with their
/// position in the hash table. The bucket occupied by the *n*th child in the
/// buffer above is identified by position of the *n*th true bit in the child
/// map, and the *n*th item's bucket corresponds to the *n*th true bit in the
/// items map.
```

### Sources/HashTreeCollections/HashNode/_HashNodeHeader.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashNodeHeader.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// The storage header in a hash tree node. This includes data about the
/// current size and capacity of the node's storage region, as well as
/// information about the currently occupied hash table buckets.
```

### Sources/HashTreeCollections/HashNode/_HashSlot.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashSlot.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// Identifies a position within a contiguous storage region within a hash tree
/// node. Hash tree nodes have two storage regions, one for items and one for
/// children; the same `_HashSlot` type is used to refer to positions within both.
///
/// We use the term "slot" to refer to internal storage entries, to avoid
/// confusion with terms that sometimes appear in public API, such as
/// "index", "position" or "offset".
```

### Sources/HashTreeCollections/HashNode/_HashStack.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_HashStack.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A fixed-size array of just enough size to hold an ancestor path in a
/// `TreeDictionary`.
```

### Sources/HashTreeCollections/HashNode/_RawHashNode.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_RawHashNode.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A type-erased node in a hash tree. This doesn't know about the user data
/// stored in the tree, but it has access to subtree counts and it can be used
/// to freely navigate within the tree structure.
///
/// This construct is powerful enough to implement APIs such as `index(after:)`,
/// `distance(from:to:)`, `index(_:offsetBy:)` in non-generic code.
```

### Sources/HashTreeCollections/HashNode/_UnsafePath.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/HashNode/_UnsafePath.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A non-owning, mutable construct representing a path to an item or child node
/// within a hash tree (or the virtual slot addressing the end of the
/// items or children region within a node).
///
/// Path values provide mutating methods to freely navigate around in the tree,
/// including basics such as descending into a child node, ascending to a
/// parent or selecting a particular item within the current node; as well as
/// more complicated methods such as finding the next/previous item in a
/// preorder walk of the tree.
///
/// Paths are, for the most part, represented by a series of slot values
/// identifying a particular branch within each level in the tree up to and
/// including the final node on the path.
///
/// However, to speed up common operations, path values also include a single
/// `_UnmanagedHashNode` reference to their final node. This reference does not
/// keep the targeted node alive -- it is the use site's responsibility to
/// ensure that the path is still valid before calling most of its operations.
///
/// Note: paths only have a direct reference to their final node. This means
/// that ascending to the parent node requires following the path from the root
/// node down. (Paths could also store references to every node alongside them
/// in a fixed-size array; this would speed up walking over the tree, but it
/// would considerably embiggen the size of the path construct.)
```

### Sources/HashTreeCollections/TreeDictionary/TreeDictionary+Equatable.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/TreeDictionary/TreeDictionary+Equatable.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//
```

### Sources/HashTreeCollections/TreeDictionary/TreeDictionary.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/TreeDictionary/TreeDictionary.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// An unordered collection of unique keys and associated values, optimized for
/// mutating shared copies and comparing different snapshots of the same
/// collection.
///
/// `TreeDictionary` has the same functionality as a standard
/// `Dictionary`, and it largely implements the same APIs: both are hashed
/// collection types with convenient and efficient ways to look up the value
/// associated with a particular key, and both types are unordered, meaning that
/// neither type provides any guarantees about the ordering of their items.
///
/// However, `TreeDictionary` is optimizing specifically for use cases
/// that need to mutate shared copies or to compare a dictionary value to one of
/// its older snapshots. To use a term from functional programming,
/// `TreeDictionary` implements a _persistent data structure_.
///
/// The standard `Dictionary` stores its members in a single, flat hash table,
/// and it implements value semantics with all-or-nothing copy-on-write
/// behavior: every time a shared copy of a dictionary is mutated, the mutation
/// needs to make a full copy of the dictionary's storage.
/// `TreeDictionary` takes a different approach: it organizes its members
/// into a tree structure, the nodes of which can be freely shared across
/// collection values. When mutating a shared copy of a dictionary value,
/// `TreeDictionary` is able to simply link the unchanged parts of the
/// tree directly into the result, saving both time and memory.
///
/// This structural sharing also makes it more efficient to compare mutated
/// dictionaries values to earlier versions of themselves. When comparing or
/// combining dictionaries, parts that are shared across both inputs can
/// typically be handled in constant time, leading to a dramatic performance
/// boost when the two inputs are still largely unchanged:
///
///     var d = TreeDictionary(
///         uniqueKeysWithValues: (0 ..< 10_000).map { ($0, 2 * $0) })
///     let copy = d
///     d[20_000] = 42 // Expected to be an O(log(n)) operation
///     let diff = d.keys.subtracting(copy.keys) // Also O(log(n))!
///     // `diff` now holds the single item 20_000.
///
/// The tree structure also eliminates the need to reserve capacity in advance:
/// `TreeDictionary` creates, destroys and resizes individual nodes as
/// needed, always consuming just enough memory to store its contents. As of
/// Swift 5.9, the standard collection types never shrink their storage, so
/// temporary storage spikes can linger as unused but still allocated memory
/// long after the collection has shrunk back to its usual size.
///
/// Of course, switching to a tree structure comes with some trade offs. In
/// particular, inserting new items, removing existing ones, and iterating over
/// a `TreeDictionary` is expected to be a constant factor slower than a
/// standard `Dictionary` -- allocating/deallocating nodes isn't free, and
/// navigating the tree structure requires more pointer dereferences than
/// accessing a flat hash table. However the algorithmic improvements above
/// usually more than make up for this, as long as the use case can make use of
/// them.
```

### Sources/HashTreeCollections/TreeSet/TreeSet.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HashTreeCollections/TreeSet/TreeSet.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// An unordered collection of unique elements, optimized for mutating shared
/// copies and comparing different snapshots of the same collection.
///
/// `TreeSet` has the same functionality as a standard `Set`, and
/// it largely implements the same APIs: both are hashed collection
/// types that conform to `SetAlgebra`, and both are unordered -- neither type
/// provides any guarantees about the ordering of their members.
///
/// However, `TreeSet` is optimizing specifically for use cases that
/// need to mutate shared copies or to compare a set value to one of its older
/// snapshots. To use a term from functional programming,
/// `TreeSet` implements a _persistent data structure_.
///
/// The standard `Set` stores its members in a single, flat hash table, and it
/// implements value semantics with all-or-nothing copy-on-write behavior: every
/// time a shared copy of a set is mutated, the mutation needs to make a full
/// copy of the set's storage. `TreeSet` takes a different approach: it
/// organizes its members into a tree structure, the nodes of which can be
/// freely shared across collection values. When mutating a shared copy of a set
/// value, `TreeSet` is able to simply link the unchanged parts of the
/// tree directly into the result, saving both time and memory.
///
/// This structural sharing also makes it more efficient to compare mutated set
/// values to earlier versions of themselves. When comparing or combining sets,
/// parts that are shared across both inputs can typically be handled in
/// constant time, leading to a dramatic performance boost when the two inputs
/// are still largely unchanged:
///
///     var set = TreeSet(0 ..< 10_000)
///     let copy = set
///     set.insert(20_000) // Expected to be an O(log(n)) operation
///     let diff = set.subtracting(copy) // Also O(log(n))!
///     // `diff` now holds the single item 20_000.
///
/// The tree structure also eliminates the need to reserve capacity in advance:
/// `TreeSet` creates, destroys and resizes individual nodes as needed,
/// always consuming just enough memory to store its contents. As of Swift 5.9,
/// the standard collection types never shrink their storage, so temporary
/// storage spikes can linger as unused but still allocated memory long after
/// the collection has shrunk back to its usual size.
///
/// Of course, switching to a tree structure comes with some trade offs. In
/// particular, inserting new items, removing existing ones, and iterating over
/// a `TreeSet` is expected to be a constant factor slower than a standard
/// `Set` -- allocating/deallocating nodes isn't free, and navigating the tree
/// structure requires more pointer dereferences than accessing a flat hash
/// table. However the algorithmic improvements above usually more than make up
/// for this, as long as the use case can make use of them.
```

### Sources/HeapModule/Heap.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/HeapModule/Heap.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//


/// A container type implementing a double-ended priority queue.
/// `Heap` is a container of `Comparable` elements that provides immediate
/// access to its minimal and maximal members, and supports removing these items
/// or inserting arbitrary new items in (amortized) logarithmic complexity.
///
///     var queue: Heap<Int> = [3, 4, 1, 2]
///     queue.insert(0)
///     print(queue.min)      // 0
///     print(queue.popMax()) // 4
///     print(queue.max)      // 3
///
/// `Heap` implements the min-max heap data structure, based on
/// [Atkinson et al. 1986].
///
/// [Atkinson et al. 1986]: https://doi.org/10.1145/6617.6621
///
/// > M.D. Atkinson, J.-R. Sack, N. Santoro, T. Strothotte.
/// "Min-Max Heaps and Generalized Priority Queues."
/// *Communications of the ACM*, vol. 29, no. 10, Oct. 1986., pp. 996-1000,
/// doi:[10.1145/6617.6621](https://doi.org/10.1145/6617.6621)
///
/// To efficiently implement these operations, a min-max heap arranges its items
/// into a complete binary tree, maintaining a specific invariant across levels,
/// called the "min-max heap property": each node at an even level in the tree
/// must be less than or equal to all its descendants, while each node at an odd
/// level in the tree must be greater than or equal to all of its descendants.
/// To achieve a compact representation, this tree is stored in breadth-first
/// order inside a single contiguous array value.
///
/// Unlike most container types, `Heap` doesn't provide a direct way to iterate
/// over the elements it contains -- it isn't a `Sequence` (nor a `Collection`).
/// This is because the order of items in a heap is unspecified and unstable:
/// it may vary between heaps that contain the same set of items, and it may
/// sometimes change in between versions of this library. In particular, the
/// items are (almost) never expected to be in sorted order.
///
/// For cases where you do need to access the contents of a heap directly and
/// you don't care about their (lack of) order, you can do so by invoking the
/// `unordered` view. This read-only view gives you direct access to the
/// underlying array value:
///
///     for item in queue.unordered {
///       ...
///     }
///
/// The name `unordered` highlights the lack of ordering guarantees on the
/// contents, and it helps avoid relying on any particular order.
```

### Sources/InternalCollectionsUtilities/Debugging.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/InternalCollectionsUtilities/Debugging.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// True if consistency checking is enabled in the implementation of the
/// Swift Collections package, false otherwise.
///
/// Documented performance promises are null and void when this property
/// returns true -- for example, operations that are documented to take
/// O(1) time might take O(*n*) time, or worse.
```

### Sources/InternalCollectionsUtilities/LifetimeOverride.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/InternalCollectionsUtilities/LifetimeOverride.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// Unsafely discard any lifetime dependency on the `dependent` argument.
/// Return a value identical to `dependent` with an immortal lifetime.
```

### Sources/InternalCollectionsUtilities/TemporaryAllocation.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/InternalCollectionsUtilities/TemporaryAllocation.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2024 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A polyfill of the typed-throws supporting `withUnsafeTemporaryAllocation` in the 6.3 stdlib.
```

### Sources/InternalCollectionsUtilities/UnsafeBitSet/_UnsafeBitSet.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/InternalCollectionsUtilities/UnsafeBitSet/_UnsafeBitSet.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// An unsafe-unowned bitset view over `UInt` storage, providing bit set
/// primitives.
```

### Sources/InternalCollectionsUtilities/_SortedCollection.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/InternalCollectionsUtilities/_SortedCollection.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A Collection type that is guaranteed to contain elements in monotonically
/// increasing order. (Duplicates are still allowed unless the collection
/// also conforms to `_UniqueCollection`.)
///
/// Types conforming to this protocol must also conform to `Collection`,
/// with an `Element` type that conforms to `Comparable`.
/// (However, this protocol does not specify these as explicit requirements,
/// to allow simple conformance tests such as `someValue is _SortedCollection`
/// to be possible.)
///
/// For any two valid indices `i` and `j` for a conforming collection `c`
/// (both below the end index), it must hold true that if `i < j`, then
/// `c[i] <= c[j]`.
```

### Sources/InternalCollectionsUtilities/_UniqueCollection.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/InternalCollectionsUtilities/_UniqueCollection.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A Collection type that is guaranteed not to contain any duplicate elements.
///
/// Types conforming to this protocol must also conform to `Collection`,
/// with an `Element` type that conforms to `Equatable`.
/// (However, this protocol does not specify these as explicit requirements,
/// to allow simple conformance tests such as `someValue is _SortedCollection`
/// to be possible.)
///
/// For any two valid indices `i` and `j` in a conforming collection `c`
/// (both below the end index), it must hold true that if `i != j` then
/// `c[i] != c[j]`.
///
/// Types that conform to this protocol should also implement the following
/// underscored requirements in a way that they never return nil values:
///
/// - `Sequence._customContainsEquatableElement`
/// - `Collection._customIndexOfEquatableElement`
/// - `Collection._customLastIndexOfEquatableElement`
///
/// The idea with these is that presumably a collection that can guarantee
/// element uniqueness has a way to quickly find existing elements.
```

### Sources/OrderedCollections/HashTable/_HashTable+CustomStringConvertible.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/OrderedCollections/HashTable/_HashTable+CustomStringConvertible.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// These are primarily for debugging.
```

### Sources/OrderedCollections/OrderedDictionary/OrderedDictionary+Move.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/OrderedCollections/OrderedDictionary/OrderedDictionary+Move.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// Reordering implementation.
//
// The keys are an `OrderedSet`. Its move relocates the keys (rearranging the
// element storage and patching the hash table) and calls back with the
// resolved plan; the dictionary uses that callback to apply the same
// rearrangement to the parallel `_values` buffer.
```

### Sources/OrderedCollections/OrderedDictionary/OrderedDictionary+Partial RangeReplaceableCollection.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/OrderedCollections/OrderedDictionary/OrderedDictionary+Partial RangeReplaceableCollection.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// The parts of RangeReplaceableCollection that OrderedDictionary is able to implement.
```

### Sources/OrderedCollections/OrderedDictionary/OrderedDictionary.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/OrderedCollections/OrderedDictionary/OrderedDictionary.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// An ordered collection of key-value pairs.
///
/// Like the standard `Dictionary`, ordered dictionaries use a hash table to
/// ensure that no two entries have the same keys, and to efficiently look up
/// values corresponding to specific keys. However, like an `Array` (and
/// unlike `Dictionary`), ordered dictionaries maintain their elements in a
/// particular user-specified order, and they support efficient random-access
/// traversal of their entries.
///
/// `OrderedDictionary` is a useful alternative to `Dictionary` when the order
/// of elements is important, or when you need to be able to efficiently access
/// elements at various positions within the collection.
///
/// You can create an ordered dictionary with any key type that conforms to the
/// `Hashable` protocol.
///
///     let responses: OrderedDictionary = [
///       200: "OK",
///       403: "Access forbidden",
///       404: "File not found",
///       500: "Internal server error",
///     ]
///
/// ### Equality of Ordered Dictionaries
///
/// Two ordered dictionaries are considered equal if they contain the same
/// elements, and *in the same order*. This matches the concept of equality of
/// an `Array`, and it is different from the unordered `Dictionary`.
///
///     let a: OrderedDictionary = [1: "one", 2: "two"]
///     let b: OrderedDictionary = [2: "two", 1: "one"]
///     a == b // false
///     b.swapAt(0, 1) // `b` now has value [1: "one", 2: "two"]
///     a == b // true
///
/// (`OrderedDictionary` only conforms to `Equatable` when its `Value` is
/// equatable.)
///
/// ### Dictionary Operations
///
/// `OrderedDictionary` provides many of the same operations as `Dictionary`.
///
/// For example, you can look up and add/remove values using the familiar
/// key-based subscript, returning an optional value:
///
///     var dictionary: OrderedDictionary<String, Int> = [:]
///     dictionary["one"] = 1
///     dictionary["two"] = 2
///     dictionary["three"] // nil
///     // dictionary is now ["one": 1, "two": 2]
///
/// If a new entry is added using the subscript setter, it gets appended to the
/// end of the dictionary. (So that by default, the dictionary contains its
/// elements in the order they were originally inserted.)
///
/// `OrderedDictionary` also implements the variant of this subscript that takes
/// a default value. Like with `Dictionary`, this is useful when you want to
/// perform in-place mutations on values:
///
///     let text = "short string"
///     var counts: OrderedDictionary<Character, Int> = [:]
///     for character in text {
///       counts[character, default: 0] += 1
///     }
///     // counts is ["s": 2, "h": 1, "o": 1,
///     //            "r": 2, "t": 2, " ": 1,
///     //            "i": 1, "n": 1, "g": 1]
///
/// If the `Value` type implements reference semantics, or when you need to
/// perform a series of individual mutations on the values, the closure-based
/// ``updateValue(forKey:default:with:)`` method provides an easier-to-use
/// alternative to the defaulted key-based subscript.
///
///     let text = "short string"
///     var counts: OrderedDictionary<Character, Int> = [:]
///     for character in text {
///       counts.updateValue(forKey: character, default: 0) { value in
///         value += 1
///       }
///     }
///     // Same result as before
///
/// (This isn't currently available on the regular `Dictionary`.)
///
/// The `Dictionary` type's original ``updateValue(_:forKey:)`` method is also
/// available, and so is ``index(forKey:)``, grouping/uniquing initializers
/// (``init(uniqueKeysWithValues:)-5ux9r``, ``init(_:uniquingKeysWith:)-2y39b``,
/// ``init(grouping:by:)-6mahw``), methods for merging one dictionary with
/// another (``merge(_:uniquingKeysWith:)-6ka2i``,
/// ``merging(_:uniquingKeysWith:)-4z49c``), filtering dictionary entries
/// (``filter(_:)``), transforming values (``mapValues(_:)``), and a combination
/// of these two (``compactMapValues(_:)``).
///
/// ### Sequence and Collection Operations
///
/// Ordered dictionaries use integer indices representing offsets from the
/// beginning of the collection. However, to avoid ambiguity between key-based
/// and indexing subscripts, `OrderedDictionary` doesn't directly conform to
/// `Collection`. Instead, it only conforms to `Sequence`, and provides a
/// random-access collection view over its key-value pairs, called
/// ``elements-swift.property``:
///
///     responses[0] // `nil` (key-based subscript)
///     responses.elements[0] // `(200, "OK")` (index-based subscript)
///
/// Because ordered dictionaries need to maintain unique keys, neither
/// `OrderedDictionary` nor its `elements` view can conform to the full
/// `MutableCollection` or `RangeReplaceableCollection` protocols.
/// However, `OrderedDictionary` is still able to implement some of the
/// requirements of these protocols. In particular, it supports permutation
/// operations from `MutableCollection`:
///
/// - ``swapAt(_:_:)``
/// - ``partition(by:)``
/// - ``sort()``, ``sort(by:)``
/// - ``shuffle()``, ``shuffle(using:)``
/// - ``reverse()``
///
/// It also supports removal operations from `RangeReplaceableCollection`:
///
/// - ``removeAll(keepingCapacity:)``
/// - ``remove(at:)``
/// - ``removeSubrange(_:)-512n3``, ``removeSubrange(_:)-8rmzx``
/// - ``removeLast()``, ``removeLast(_:)``
/// - ``removeFirst()``, ``removeFirst(_:)``
/// - ``removeAll(where:)``
///
/// `OrderedDictionary` also implements ``reserveCapacity(_:)`` from
/// `RangeReplaceableCollection`, to allow for efficient insertion of a known
/// number of elements. (However, unlike `Array` and `Dictionary`,
/// `OrderedDictionary` does not provide a `capacity` property.)
///
/// ### Keys and Values Views
///
/// Like the standard `Dictionary`, `OrderedDictionary` provides ``keys`` and
/// ``values-swift.property`` properties that provide lightweight views into
/// the corresponding parts of the dictionary.
///
/// The ``keys`` collection is of type ``OrderedSet``, containing all the keys
/// in the original dictionary.
///
///     let d: OrderedDictionary = [2: "two", 1: "one", 0: "zero"]
///     d.keys // [2, 1, 0] as OrderedSet<Int>
///
/// The ``keys`` property is read-only, so you cannot mutate the dictionary
/// through it. However, it returns an ordinary ordered set value, which can be
/// copied out and then mutated if desired. (Such mutations won't affect the
/// original dictionary value.)
///
/// The ``values-swift.property`` collection is a mutable random-access
/// ordered collection of the values in the dictionary:
///
///     d.values // "two", "one", "zero"
///     d.values[2] = "nada"
///     // `d` is now [2: "two", 1: "one", 0: "nada"]
///     d.values.sort()
///     // `d` is now [2: "nada", 1: "one", 0: "two"]
///
/// Both views store their contents in regular `Array` values, accessible
/// through their ``elements-swift.property`` property.
///
/// ## Performance
///
/// An ordered dictionary consists of an ``OrderedSet`` of keys, alongside a
/// regular `Array` value that contains their associated values.
/// The performance characteristics of `OrderedDictionary` are mostly dictated
/// by this setup.
///
/// - Looking up a member in an ordered dictionary is expected to execute
///    a constant number of hashing and equality check operations, just like
///    the standard `Dictionary`.
/// - `OrderedDictionary` is also able to append new items at the end of the
///    dictionary with an expected amortized complexity of O(1), similar to
///    inserting new items into `Dictionary`.
/// - Unfortunately, removing or inserting items at the start or middle of an
///    `OrderedDictionary` has linear complexity, making these significantly
///    slower than `Dictionary`.
/// - Storing keys and values outside of the hash table makes
///    `OrderedDictionary` more memory efficient than most alternative
///    ordered dictionary representations. It can sometimes also be more memory
///    efficient than the standard `Dictionary`, despote the additional
///    functionality of preserving element ordering.
///
/// Like all hashed data structures, ordered dictionaries are extremely
/// sensitive to the quality of the `Key` type's `Hashable` conformance.
/// All complexity guarantees are null and void if `Key` implements `Hashable`
/// incorrectly.
///
/// See ``OrderedSet`` for a more detailed discussion of these performance
/// characteristics.
```

### Sources/OrderedCollections/OrderedSet/OrderedSet+Partial MutableCollection.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/OrderedCollections/OrderedSet/OrderedSet+Partial MutableCollection.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// The parts of MutableCollection that OrderedSet is able to implement.
```

### Sources/OrderedCollections/OrderedSet/OrderedSet+Partial RangeReplaceableCollection.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/OrderedCollections/OrderedSet/OrderedSet+Partial RangeReplaceableCollection.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// The parts of RangeReplaceableCollection that OrderedSet is able to implement.
```

### Sources/OrderedCollections/OrderedSet/OrderedSet+Partial SetAlgebra formIntersection.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/OrderedCollections/OrderedSet/OrderedSet+Partial SetAlgebra formIntersection.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// `OrderedSet` does not directly conform to `SetAlgebra` because its definition
// of equality conflicts with `SetAlgebra` requirements. However, it still
// implements most `SetAlgebra` requirements (except `insert`, which is replaced
// by `append`).
//
// `OrderedSet` also provides an `unordered` view that explicitly conforms to
// `SetAlgebra`. That view implements `Equatable` by ignoring element order,
// so it can satisfy `SetAlgebra` requirements.
```

### Sources/RopeModule/Rope/Basics/Rope.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/RopeModule/Rope/Basics/Rope.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// An ordered data structure of `Element` values that organizes itself into a tree.
/// The rope is augmented by the commutative group specified by `Element.Summary`, enabling
/// quick lookup operations.
```

### Sources/RopeModule/Rope/Basics/RopeElement.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/RopeModule/Rope/Basics/RopeElement.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// The element type of a rope. Rope elements are expected to be container types
/// of their own, with logical positions within them addressed by an `Index`
/// type, similar to `Collection` indices.
///
/// However, rope elements aren't required conform to `Collection`. In fact,
/// they often support multiple different ways to interpret/project their
/// contents, similar to `String`'s views. In some cases, they may just be
/// individual, undivisable items of varying sizes -- although it's usually
/// a better to use a simple fixed-size collection type instead.
///
/// Each such projection may come with a different idea for how large a rope
/// element is -- this is modeled by the `RopeSummary` and `RopeMetric`
/// protocols. The `summary` property returns the size of the element as an
/// additive value, which can be projected to integer sizes using one of the
/// associated rope metrics.
```

### Sources/RopeModule/Rope/Basics/RopeSummary.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/RopeModule/Rope/Basics/RopeSummary.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// A commutative group that is used to augment a tree, enabling quick lookup operations.
```

### Sources/RopeModule/Rope/Basics/_RopeItem.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/RopeModule/Rope/Basics/_RopeItem.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// An internal protocol describing a summarizable entity that isn't a full `RopeElement`.
///
/// Used as an implementation detail to increase code reuse across internal nodes and leaf nodes.
/// (Ideally `Rope._Node` would just conform to the full `RopeElement` protocol on its own, but
/// while that's an obvious refactoring idea, it hasn't happened yet.)
```

### Sources/RopeModule/Utilities/String.Index+ABI.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/RopeModule/Utilities/String.Index+ABI.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2023 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

// Bits of String.Index that are ABI but aren't exposed by public API.
```

### Sources/TrailingElementsModule/TrailingElements.swift:embedded-notice

Source: https://github.com/apple/swift-collections/blob/3b69cedbaa49957e97c092ae400bb57602ef941f/Sources/TrailingElementsModule/TrailingElements.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

/// Describes a type that has some number of elements following it directly
/// in memory. Such types are generally used with the `TrailingArray`
/// type, which manages storage for the header and its trailing elements.
```

## swift-crypto 5.0.3

Repository: https://github.com/apple/swift-crypto.git

Revision: `c2cbadd7263439d8015189668f96ff5b5be565ce`

### LICENSE.txt

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/LICENSE.txt

```text

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

### NOTICE.txt

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/NOTICE.txt

```text
                            The SwiftCrypto Project
                            =======================

Please visit the SwiftCrypto web site for more information:

  * https://github.com/apple/swift-crypto

Copyright 2019 The SwiftCrypto Project

The SwiftCrypto Project licenses this file to you under the Apache License,
version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at:

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.

Also, please refer to each LICENSE.<component>.txt file, which is located in
the 'license' directory of the distribution file, for the license terms of the
components that this product depends on.

-------------------------------------------------------------------------------

This product contains test vectors from Google's wycheproof project.

  * LICENSE (Apache License 2.0):
    * https://github.com/C2SP/wycheproof/blob/31387e2cd596587c859c611027b6a44d2e2b65ff/LICENSE
  * HOMEPAGE:
    * https://github.com/google/wycheproof

---

This product contains a derivation of various files from SwiftNIO.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/apple/swift-nio
```

### Benchmarks/Benchmarks/Benchmarks.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Benchmarks/Benchmarks/Benchmarks.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Package.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Package.swift

```text
// swift-tools-version:6.2
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2023 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CCryptoBoringSSL/crypto/aes/aes.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/aes/aes.cc

```text
// Copyright 2025 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/asn1/a_bitstr.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/asn1/a_bitstr.cc

```text
// Copyright 1995-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/asn1/a_mbstr.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/asn1/a_mbstr.cc

```text
// Copyright 1999-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/asn1/a_strex.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/asn1/a_strex.cc

```text
// Copyright 2000-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/asn1/internal.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/asn1/internal.h

```text
// Copyright 2005-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/asn1/posix_time.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/asn1/posix_time.cc

```text
// Copyright 2022 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/asn1/posix_time.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/asn1/posix_time.cc

```text
// Inspired by algorithms presented in
// https://howardhinnant.github.io/date_algorithms.html
// (Public Domain)
```

### Sources/CCryptoBoringSSL/crypto/bcm_support.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/bcm_support.h

```text
// Copyright 2024 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/bio/socket_helper.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/bio/socket_helper.cc

```text
// Copyright 2014 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/blake2/blake2.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/blake2/blake2.cc

```text
// Copyright 2021 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/bn/bn_asn1.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/bn/bn_asn1.cc

```text
// Copyright 2015 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/bytestring/asn1_compat.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/bytestring/asn1_compat.cc

```text
// Copyright 2016 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/bytestring/unicode.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/bytestring/unicode.cc

```text
// Copyright 2018 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/chacha/chacha.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/chacha/chacha.cc

```text
// Adapted from the public domain, estream code by D. Bernstein.
```

### Sources/CCryptoBoringSSL/crypto/cipher/e_aesctrhmac.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/cipher/e_aesctrhmac.cc

```text
// Copyright 2017 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/cipher/tls_cbc.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/cipher/tls_cbc.cc

```text
// Copyright 2012-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/cpu_aarch64_openbsd.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/cpu_aarch64_openbsd.cc

```text
// Copyright (c) 2022, Robert Nagy <robert.nagy@gmail.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/cpu_aarch64_sysreg.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/cpu_aarch64_sysreg.cc

```text
// Copyright 2023 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/cpu_aarch64_win.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/cpu_aarch64_win.cc

```text
// Copyright 2018 The BoringSSL Authors
// Copyright (c) 2020, Arm Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/curve25519/asm/x25519-asm-arm.S:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/curve25519/asm/x25519-asm-arm.S

```text
/* This file is taken from crypto_scalarmult/curve25519/neon2/scalarmult.s in
 * SUPERCOP 20141124 (http://bench.cr.yp.to/supercop.html). That code is public
 * domain licensed but the standard Apache 2.0 license is included above to keep
 * licensing simple. */
```

### Sources/CCryptoBoringSSL/crypto/curve25519/curve25519.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/curve25519/curve25519.cc

```text
// Copyright 2020 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/curve25519/curve25519.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/curve25519/curve25519.cc

```text
// Some of this code is taken from the ref10 version of Ed25519 in SUPERCOP
// 20141124 (http://bench.cr.yp.to/supercop.html). That code is released as
// public domain. Other parts have been replaced to call into code generated by
// Fiat (https://github.com/mit-plv/fiat-crypto) in //third_party/fiat.
//
// The field functions are shared by Ed25519 and X25519 where possible.
```

### Sources/CCryptoBoringSSL/crypto/dh/params.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/dh/params.cc

```text
// Copyright 2011-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/ec/ec_asn1.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/ec/ec_asn1.cc

```text
// Copyright 2002-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/ec/ec_derive.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/ec/ec_derive.cc

```text
// Copyright 2019 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/ecdh/ecdh.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/ecdh/ecdh.cc

```text
// Copyright 2002-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/evp/evp_ctx.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/evp/evp_ctx.cc

```text
// Copyright 2006-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/evp/p_dh.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/evp/p_dh.cc

```text
// Copyright 2006-2019 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/evp/p_dh_asn1.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/evp/p_dh_asn1.cc

```text
// Copyright 2006-2021 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/evp/scrypt.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/evp/scrypt.cc

```text
// Copyright 2015-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/aes/cbc.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/aes/cbc.cc.inc

```text
// Copyright 2008-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/aes/gcm.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/aes/gcm.cc.inc

```text
// Copyright 2010-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/bn/asm/x86_64-gcc.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/bn/asm/x86_64-gcc.cc.inc

```text
/* x86_64 BIGNUM accelerator version 0.1, December 2002.
 *
 * Implemented by Andy Polyakov <appro@fy.chalmers.se> for the OpenSSL
 * project.
 *
 * Rights for redistribution and usage in source and binary forms are
 * granted according to the License. Warranty of any kind is disclaimed.
 *
 * Q. Version 0.1? It doesn't sound like Andy, he used to assign real
 *    versions, like 1.0...
 * A. Well, that's because this code is basically a quick-n-dirty
 *    proof-of-concept hack. As you can see it's implemented with
 *    inline assembler, which means that you're bound to GCC and that
 *    there might be enough room for further improvement.
 *
 * Q. Why inline assembler?
 * A. x86_64 features own ABI which I'm not familiar with. This is
 *    why I decided to let the compiler take care of subroutine
 *    prologue/epilogue as well as register allocation. For reference.
 *    Win64 implements different ABI for AMD64, different from Linux.
 *
 * Q. How much faster does it get?
 * A. 'apps/openssl speed rsa dsa' output with no-asm:
 *
 *	                  sign    verify    sign/s verify/s
 *	rsa  512 bits   0.0006s   0.0001s   1683.8  18456.2
 *	rsa 1024 bits   0.0028s   0.0002s    356.0   6407.0
 *	rsa 2048 bits   0.0172s   0.0005s     58.0   1957.8
 *	rsa 4096 bits   0.1155s   0.0018s      8.7    555.6
 *	                  sign    verify    sign/s verify/s
 *	dsa  512 bits   0.0005s   0.0006s   2100.8   1768.3
 *	dsa 1024 bits   0.0014s   0.0018s    692.3    559.2
 *	dsa 2048 bits   0.0049s   0.0061s    204.7    165.0
 *
 *    'apps/openssl speed rsa dsa' output with this module:
 *
 *	                  sign    verify    sign/s verify/s
 *	rsa  512 bits   0.0004s   0.0000s   2767.1  33297.9
 *	rsa 1024 bits   0.0012s   0.0001s    867.4  14674.7
 *	rsa 2048 bits   0.0061s   0.0002s    164.0   5270.0
 *	rsa 4096 bits   0.0384s   0.0006s     26.1   1650.8
 *	                  sign    verify    sign/s verify/s
 *	dsa  512 bits   0.0002s   0.0003s   4442.2   3786.3
 *	dsa 1024 bits   0.0005s   0.0007s   1835.1   1497.4
 *	dsa 2048 bits   0.0016s   0.0020s    620.4    504.6
 *
 *    For the reference. IA-32 assembler implementation performs
 *    very much like 64-bit code compiled with no-asm on the same
 *    machine.
 */
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/bn/internal.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/bn/internal.h

```text
// Copyright 1995-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/bn/montgomery_inv.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/bn/montgomery_inv.cc.inc

```text
// Copyright 2016 Brian Smith.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/bn/rsaz_exp.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/bn/rsaz_exp.cc.inc

```text
// Copyright 2013-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2012, Intel Corporation. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Originally written by Shay Gueron (1, 2), and Vlad Krasnov (1)
// (1) Intel Corporation, Israel Development Center, Haifa, Israel
// (2) University of Haifa, Israel
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/cipher/e_aes.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/cipher/e_aes.cc.inc

```text
// Copyright 2001-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/ec.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/ec.cc.inc

```text
// Copyright 2001-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/oct.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/oct.cc.inc

```text
// Copyright 2011-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/p224-64.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/p224-64.cc.inc

```text
// A 64-bit implementation of the NIST P-224 elliptic curve point multiplication
//
// Inspired by Daniel J. Bernstein's public domain nistp224 implementation
// and Adam Langley's public domain 64-bit C implementation of curve25519.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/p256-nistz-table.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/p256-nistz-table.h

```text
// Copyright 2014-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2015, Intel Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/p256-nistz.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/ec/p256-nistz.cc.inc

```text
// Copyright 2014-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2014, Intel Corporation. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Originally written by Shay Gueron (1, 2), and Vlad Krasnov (1)
// (1) Intel Corporation, Israel Development Center, Haifa, Israel
// (2) University of Haifa, Israel
//
// Reference:
// S.Gueron and V.Krasnov, "Fast Prime Field Elliptic Curve Cryptography with
//                          256 Bit Primes"
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/entropy/sha512.cc.inc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/entropy/sha512.cc.inc

```text
// Copyright 2004-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/fipsmodule/service_indicator/internal.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/fipsmodule/service_indicator/internal.h

```text
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/hrss/asm/poly_rq_mul.S:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/hrss/asm/poly_rq_mul.S

```text
// Copyright (c) 2017, the HRSS authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/poly1305/poly1305_arm.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/poly1305/poly1305_arm.cc

```text
// This implementation was taken from the public domain, neon2 version in
// SUPERCOP by D. J. Bernstein and Peter Schwabe.
```

### Sources/CCryptoBoringSSL/crypto/poly1305/poly1305_arm_asm.S:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/poly1305/poly1305_arm_asm.S

```text
# This implementation was taken from the public domain, neon2 version in
# SUPERCOP by D. J. Bernstein and Peter Schwabe.
```

### Sources/CCryptoBoringSSL/crypto/rsa/rsa_print.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/rsa/rsa_print.cc

```text
// Copyright 2006-2017 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/x509/internal.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/x509/internal.h

```text
// Copyright 2013-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/crypto/x509/v3_ncons.cc:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/crypto/x509/v3_ncons.cc

```text
// Copyright 2003-2016 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/gen/bcm/sha256-armv8-apple.S:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/gen/bcm/sha256-armv8-apple.S

```text
// Copyright 2014-2020 The OpenSSL Project Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CCryptoBoringSSL/include/CCryptoBoringSSL.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/include/CCryptoBoringSSL.h

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CCryptoBoringSSL/include/CCryptoBoringSSL_ec.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CCryptoBoringSSL/include/CCryptoBoringSSL_ec.h

```text
// Copyright 2000-2016 The OpenSSL Project Authors. All Rights Reserved.
// Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
```

### Sources/CXKCP/FIPS202-opt64/KeccakHash.c:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CXKCP/FIPS202-opt64/KeccakHash.c

```text
/*
The eXtended Keccak Code Package (XKCP)
https://github.com/XKCP/XKCP

Keccak, designed by Guido Bertoni, Joan Daemen, Michaël Peeters and Gilles Van Assche.

Implementation by the designers, hereby denoted as "the implementer".

For more information, feedback or questions, please refer to the Keccak Team website:
https://keccak.team/

To the extent possible under law, the implementer has waived all copyright
and related or neighboring rights to the source code in this file.
http://creativecommons.org/publicdomain/zero/1.0/
*/
```

### Sources/CXKCP/FIPS202-opt64/KeccakP-1600-64.macros:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CXKCP/FIPS202-opt64/KeccakP-1600-64.macros

```text
/*
The eXtended Keccak Code Package (XKCP)
https://github.com/XKCP/XKCP

The Keccak-p permutations, designed by Guido Bertoni, Joan Daemen, Michaël Peeters and Gilles Van Assche.

Implementation by Gilles Van Assche and Ronny Van Keer, hereby denoted as "the implementer".

For more information, feedback or questions, please refer to the Keccak Team website:
https://keccak.team/

To the extent possible under law, the implementer has waived all copyright
and related or neighboring rights to the source code in this file.
http://creativecommons.org/publicdomain/zero/1.0/
*/
```

### Sources/CXKCP/FIPS202-opt64/KeccakP-1600-SnP.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CXKCP/FIPS202-opt64/KeccakP-1600-SnP.h

```text
/*
The eXtended Keccak Code Package (XKCP)
https://github.com/XKCP/XKCP

The Keccak-p permutations, designed by Guido Bertoni, Joan Daemen, Michaël Peeters and Gilles Van Assche.

Implementation by Gilles Van Assche and Ronny Van Keer, hereby denoted as "the implementer".

For more information, feedback or questions, please refer to the Keccak Team website:
https://keccak.team/

To the extent possible under law, the implementer has waived all copyright
and related or neighboring rights to the source code in this file.
http://creativecommons.org/publicdomain/zero/1.0/

---

Please refer to SnP-documentation.h for more details.
*/
```

### Sources/CXKCP/FIPS202-opt64/KeccakP-1600-opt64.c:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CXKCP/FIPS202-opt64/KeccakP-1600-opt64.c

```text
/*
The eXtended Keccak Code Package (XKCP)
https://github.com/XKCP/XKCP

The Keccak-p permutations, designed by Guido Bertoni, Joan Daemen, Michaël Peeters and Gilles Van Assche.

Implementation by Gilles Van Assche and Ronny Van Keer, hereby denoted as "the implementer".

For more information, feedback or questions, please refer to the Keccak Team website:
https://keccak.team/

To the extent possible under law, the implementer has waived all copyright
and related or neighboring rights to the source code in this file.
http://creativecommons.org/publicdomain/zero/1.0/

---

This file implements Keccak-p[1600] in a SnP-compatible way.
Please refer to SnP-documentation.h for more details.

This implementation comes with KeccakP-1600-SnP.h in the same folder.
Please refer to LowLevel.build for the exact list of other files it must be combined with.
*/
```

### Sources/CXKCP/FIPS202-opt64/SimpleFIPS202.c:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CXKCP/FIPS202-opt64/SimpleFIPS202.c

```text
/*
The eXtended Keccak Code Package (XKCP)
https://github.com/XKCP/XKCP

Keccak, designed by Guido Bertoni, Joan Daemen, Michaël Peeters and Gilles Van Assche.

Implementation by Gilles Van Assche, hereby denoted as "the implementer".

For more information, feedback or questions, please refer to the Keccak Team website:
https://keccak.team/

To the extent possible under law, the implementer has waived all copyright
and related or neighboring rights to the source code in this file.
http://creativecommons.org/publicdomain/zero/1.0/
*/
```

### Sources/CXKCP/FIPS202-opt64/SnP-Relaned.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CXKCP/FIPS202-opt64/SnP-Relaned.h

```text
/*
The eXtended Keccak Code Package (XKCP)
https://github.com/XKCP/XKCP

Implementation by Gilles Van Assche and Ronny Van Keer, hereby denoted as "the implementer".

For more information, feedback or questions, please refer to the Keccak Team website:
https://keccak.team/

To the extent possible under law, the implementer has waived all copyright
and related or neighboring rights to the source code in this file.
http://creativecommons.org/publicdomain/zero/1.0/

---

This file contains macros that help implement a permutation in a SnP-compatible way.
It converts an implementation that implement state input/output functions
in a lane-oriented fashion (i.e., using SnP_AddLanes() and SnP_AddBytesInLane,
and similarly for Overwite, Extract and ExtractAndAdd) to the byte-oriented SnP.
Please refer to SnP-documentation.h for more details.
*/
```

### Sources/CXKCP/FIPS202-opt64/align.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CXKCP/FIPS202-opt64/align.h

```text
/*
The eXtended Keccak Code Package (XKCP)
https://github.com/XKCP/XKCP

Implementation by Gilles Van Assche and Ronny Van Keer, hereby denoted as "the implementer".

For more information, feedback or questions, please refer to the Keccak Team website:
https://keccak.team/

To the extent possible under law, the implementer has waived all copyright
and related or neighboring rights to the source code in this file.
http://creativecommons.org/publicdomain/zero/1.0/
*/
```

### Sources/CXKCP/FIPS202-opt64/brg_endian.h:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CXKCP/FIPS202-opt64/brg_endian.h

```text
/*
 ---------------------------------------------------------------------------
 Copyright (c) 1998-2008, Brian Gladman, Worcester, UK. All rights reserved.

 LICENSE TERMS

 The redistribution and use of this software (with or without changes)
 is allowed without the payment of fees or royalties provided that:

  1. source code distributions include the above copyright notice, this
     list of conditions and the following disclaimer;

  2. binary distributions include the above copyright notice, this list
     of conditions and the following disclaimer in their documentation;

  3. the name of the copyright holder is not used to endorse products
     built using this software without specific written permission.

 DISCLAIMER

 This software is provided 'as is' with no explicit or implied warranties
 in respect of its properties, including, but not limited to, correctness
 and/or fitness for purpose.
 ---------------------------------------------------------------------------
 Issue Date: 20/12/2007
 Changes for ARM 9/9/2010
*/
```

### Sources/Crypto/AEADs/AES/GCM/AES-GCM.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/Crypto/AEADs/AES/GCM/AES-GCM.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/Crypto/CryptoError_boring.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/Crypto/CryptoError_boring.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2025 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/Crypto/KEM/BoringSSL/MLKEM_boring.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/Crypto/KEM/BoringSSL/MLKEM_boring.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2024-2025 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/Crypto/Key Wrapping/BoringSSL/AESWrap_boring.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/Crypto/Key Wrapping/BoringSSL/AESWrap_boring.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/Crypto/Signatures/BoringSSL/MLDSA_boring.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/Crypto/Signatures/BoringSSL/MLDSA_boring.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/Crypto/Util/BoringSSL/InlineArray+withBytes_boring.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/Crypto/Util/BoringSSL/InlineArray+withBytes_boring.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/Crypto/Util/BoringSSL/_CryptoModuleAnchor.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/Crypto/Util/BoringSSL/_CryptoModuleAnchor.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2024-2026 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CryptoBoringWrapper/AEAD/BoringSSLAEAD.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CryptoBoringWrapper/AEAD/BoringSSLAEAD.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2022 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CryptoBoringWrapper/CryptoKitErrors_boring.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CryptoBoringWrapper/CryptoKitErrors_boring.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2021 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CryptoExtras/AES/AES_CBC.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CryptoExtras/AES/AES_CBC.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CryptoExtras/AES/AES_GCM_SIV.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CryptoExtras/AES/AES_GCM_SIV.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2022 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CryptoExtras/Key Derivation/PBKDF2/BoringSSL/PBKDF2_boring.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CryptoExtras/Key Derivation/PBKDF2/BoringSSL/PBKDF2_boring.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2021-2024 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CryptoExtras/Util/ThreadSpecific/ThreadOps.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CryptoExtras/Util/ThreadSpecific/ThreadOps.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2014 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CryptoExtras/Util/ThreadSpecific/ThreadPosix.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Sources/CryptoExtras/Util/ThreadSpecific/ThreadPosix.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Tests/CryptoExtrasTests/TestRSAEncryption.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Tests/CryptoExtrasTests/TestRSAEncryption.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) YEARS Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Tests/CryptoExtrasTests/Utils/RFCVector.swift:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/Tests/CryptoExtrasTests/Utils/RFCVector.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCrypto open source project
//
// Copyright (c) 2019-2024 Apple Inc. and the SwiftCrypto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCrypto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### scripts/patch-1-inttypes.patch:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/scripts/patch-1-inttypes.patch

```text
 // limitations under the License.
```

### scripts/patch-2-more-inttypes.patch:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/scripts/patch-2-more-inttypes.patch

```text
 // See the License for the specific language governing permissions and
 // limitations under the License.
```

### scripts/vendor-boringssl.sh:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/scripts/vendor-boringssl.sh

```text
# This was substantially adapted from grpc-swift's vendor-boringssl.sh script.
# The license for the original work is reproduced below. See NOTICES.txt for
# more.
```

### scripts/vendor-boringssl.sh:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/scripts/vendor-boringssl.sh

```text
# Copyright 2016, gRPC Authors All rights reserved.
```

### scripts/vendor-boringssl.sh:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/scripts/vendor-boringssl.sh

```text
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
```

### scripts/vendor-boringssl.sh:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/scripts/vendor-boringssl.sh

```text
#     http://www.apache.org/licenses/LICENSE-2.0
```

### scripts/vendor-boringssl.sh:embedded-notice

Source: https://github.com/apple/swift-crypto/blob/c2cbadd7263439d8015189668f96ff5b5be565ce/scripts/vendor-boringssl.sh

```text
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
```

## swift-log 1.16.1

Repository: https://github.com/apple/swift-log.git

Revision: `4038b6a4f74a1426f47eb1dd5b4bb5628a15d597`

### LICENSE.txt

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/LICENSE.txt

```text

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

### NOTICE.txt

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/NOTICE.txt

```text

                            The SwiftLog Project
                            ========================

Please visit the SwiftLog web site for more information:

  * https://github.com/apple/swift-log

Copyright 2018, 2019 The SwiftLog Project

The SwiftLog Project licenses this file to you under the Apache License,
version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at:

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.

Also, please refer to each LICENSE.<component>.txt file, which is located in
the 'license' directory of the distribution file, for the license terms of the
components that this product depends on.

-------------------------------------------------------------------------------

This product contains a derivation of the lock implementation and various
scripts from SwiftNIO.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/apple/swift-nio
```

### Sources/InMemoryLogging/InMemoryLogHandler.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/InMemoryLogging/InMemoryLogHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2022 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/Logging/Handlers/MultiplexLogHandler.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/Handlers/MultiplexLogHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A pseudo log handler that sends messages to multiple other log handlers.
///
/// ### Effective Logger.Level
///
/// When first initialized, the multiplex log handlers' log level is automatically set to the minimum of all the
/// provided log handlers.
/// This ensures that each of the handlers are able to log at their appropriate level
/// any log events they might be interested in.
///
/// Example:
/// If log handler `A` is logging at `.debug` level, and log handler `B` is logging at `.info` level, the log level of the constructed
/// `MultiplexLogHandler([A, B])` is set to `.debug`. This means that this handler will operate on debug messages,
/// while only logged by the underlying `A` log handler (since `B`'s log level is `.info`
/// and thus it would not actually log that log message).
///
/// If the log level is _set_ on a `Logger` backed by an `MultiplexLogHandler` the log level applies to *all*
/// underlying log handlers, allowing a logger to still select at what level it wants to log regardless of if the underlying
/// handler is a multiplex or a normal one. If for some reason one might want to not allow changing a log level of a specific
/// handler passed into the multiplex log handler, this is possible by wrapping it in a handler which ignores any log level changes.
///
/// ### Effective Logger.Metadata
///
/// Since a `MultiplexLogHandler` is a combination of multiple log handlers, the handling of metadata can be non-obvious.
/// For example, the underlying log handlers may have metadata of their own set before they are used to initialize the multiplex log handler.
///
/// The multiplex log handler acts purely as proxy and does not make any changes to underlying handler metadata other than
/// proxying writes that users made on a `Logger` instance backed by this handler.
///
/// Setting metadata is always proxied through to _all_ underlying handlers, meaning that if a modification like
/// `logger[metadataKey: "x"] = "y"` is made, all the underlying log handlers used to create the multiplex handler
/// observe this change.
///
/// Reading metadata from the multiplex log handler MAY need to pick one of conflicting values if the underlying log handlers
/// were previously initiated with metadata before passing them into the multiplex handler. The multiplex handler uses
/// the order in which the handlers were passed in during its initialization as a priority indicator - the first handler's
/// values are more important than the next handlers values, etc.
///
/// Example:
/// If the multiplex log handler was initiated with two handlers like this: `MultiplexLogHandler([handler1, handler2])`.
/// The handlers each have some already set metadata: `handler1` has metadata values for keys `one` and `all`, and `handler2`
/// has values for keys `two` and `all`.
///
/// A query through the multiplex log handler the key `one` naturally returns `handler1`'s value, and a query for `two`
/// naturally returns `handler2`'s value.
/// Querying for the key `all` will return `handler1`'s value, as that handler has a high priority,
/// as indicated by its earlier position in the initialization, than the second handler.
/// The same rule applies when querying for the `metadata` property of the multiplex log handler; it constructs `Metadata` uniquing values.
```

### Sources/Logging/Handlers/StreamLogHandler.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/Handlers/StreamLogHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/Logging/Handlers/SwiftLogNoOpLogHandler.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/Handlers/SwiftLogNoOpLogHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A no-operation log handler, used when no logging is required
```

### Sources/Logging/Locks.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/Locks.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2026 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2026 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/Logging/LogEvent.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/LogEvent.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A log event that contains all the information about a single log statement.
///
/// `LogEvent` is passed to a ``LogHandler`` via ``LogHandler/log(event:)`` and carries every piece of data emitted
/// at the log call site. Handlers may inspect, modify, or forward any of the event's properties.
///
/// All properties are mutable so that handler wrappers (for example ``MultiplexLogHandler``) can rewrite fields
/// such as metadata or source before forwarding to downstream handlers.
```

### Sources/Logging/LogHandler.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/LogHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A log handler provides an implementation of a logging backend.
///
/// This type is an implementation detail and should not normally be used, unless you implement your own logging backend.
/// To use the SwiftLog API, please refer to the documentation of ``Logger``.
///
/// # Implementation requirements
///
/// To implement your own `LogHandler` you should respect a few requirements that are necessary so applications work
/// as expected, regardless of the selected `LogHandler` implementation.
///
/// - The ``LogHandler`` must be a `struct`.
/// - The metadata and `logLevel` properties must be implemented so that setting them on a `Logger` does not affect
///   other instances of `Logger`.
///
/// ### Treat log level & metadata as values
///
/// When developing your `LogHandler`, please make sure the following test works.
///
/// ```swift
/// @Test
/// func logHandlerValueSemantics() {
///     LoggingSystem.bootstrap(MyLogHandler.init)
///     var logger1 = Logger(label: "first logger")
///     logger1.logLevel = .debug
///     logger1[metadataKey: "only-on"] = "first"
///
///     var logger2 = logger1
///     logger2.logLevel = .error                  // Must not affect logger1
///     logger2[metadataKey: "only-on"] = "second" // Must not affect logger1
///
///     // These expectations must pass
///     #expect(logger1.logLevel == .debug)
///     #expect(logger2.logLevel == .error)
///     #expect(logger1[metadataKey: "only-on"] == "first")
///     #expect(logger2[metadataKey: "only-on"] == "second")
/// }
/// ```
///
/// ### Special cases
///
/// In certain special cases, the log level behaving like a value on `Logger` might not be what you want.
/// For example, you might want to set the log level across _all_ `Logger`s to `.debug` when a signal
/// (for example `SIGUSR1`) is received to be able to debug special failures in production.
/// This special case is acceptable but please create a solution specific to your `LogHandler` implementation to achieve that.
///
/// The following code illustrates an example implementation of this behavior.
/// On reception of the signal you would call
/// `LogHandlerWithGlobalLogLevelOverride.overrideGlobalLogLevel = .debug`, for example.
///
/// ```swift
/// import class Foundation.NSLock
///
/// public struct LogHandlerWithGlobalLogLevelOverride: LogHandler {
///     // The static properties hold the globally overridden
///     // log level (if overridden).
///     private static let overrideLock = NSLock()
///     private static var overrideLogLevel: Logger.Level? = nil
///
///     // this holds the log level if not overridden
///     private var _logLevel: Logger.Level = .info
///
///     // metadata storage
///     public var metadata: Logger.Metadata = [:]
///
///     public init(label: String) {
///         // [...]
///     }
///
///     public var logLevel: Logger.Level {
///         // When asked for the log level, check
///         // if it was globally overridden or not.
///         get {
///             LogHandlerWithGlobalLogLevelOverride.overrideLock.lock()
///             defer { LogHandlerWithGlobalLogLevelOverride.overrideLock.unlock() }
///             return LogHandlerWithGlobalLogLevelOverride.overrideLogLevel ?? self._logLevel
///         }
///         // Set the log level whenever asked
///         // (note: this might not have an effect if globally
///         // overridden).
///         set {
///             self._logLevel = newValue
///         }
///     }
///
///     public func log(event: LogEvent) {
///         // [...]
///     }
///
///     public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
///         get {
///             return self.metadata[metadataKey]
///         }
///         set(newValue) {
///             self.metadata[metadataKey] = newValue
///         }
///     }
///
///     // This is the function to globally override the log level,
///     // it is not part of the `LogHandler` protocol.
///     public static func overrideGlobalLogLevel(_ logLevel: Logger.Level) {
///         LogHandlerWithGlobalLogLevelOverride.overrideLock.lock()
///         defer { LogHandlerWithGlobalLogLevelOverride.overrideLock.unlock() }
///         LogHandlerWithGlobalLogLevelOverride.overrideLogLevel = logLevel
///     }
/// }
/// ```
///
/// > Note: The above `LogHandler` still passes the 'log level is a value' test above it if the global log
/// > level has not been overridden. Most importantly, it passes the requirement listed above: A change to the log
/// > level on one `Logger` should not affect the log level of another `Logger` variable.
```

### Sources/Logging/Logger+Attributes.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/Logger+Attributes.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// MARK: - MetadataValueAttributes storage
```

### Sources/Logging/Logger+With.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/Logger+With.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// MARK: - withLogger() free functions for task-local logger

/// Runs `operation` with `logger` bound to the task-local context.
///
/// Code called within `operation` can read the logger via ``Logger/current`` without an
/// explicit parameter. Binding a different logger with this overload **replaces** the
/// current task-local logger; any metadata accumulated by an outer
/// ``withLogger(mergingMetadata:_:)-2c7dy`` or
/// ``withLogger(logLevel:handler:metadata:_:)-2pd9p``
/// scope is not carried over. Use the modifying overloads to layer or replace aspects
/// of the current logger instead.
///
/// This overload is the application-bootstrap binding mechanism: pass a `Logger`
/// constructed via ``Logger/init(label:)`` at your application entry point. Because
/// ``Logger/init(label:)`` consults `LoggingSystem.factory`, the constructed `Logger`
/// only carries a useful handler once ``LoggingSystem/bootstrap(_:)`` has been called.
/// For mid-call-tree backend swaps that should work without bootstrap (tests, scoped
/// routing), use ``withLogger(logLevel:handler:metadata:_:)-2pd9p``
/// instead — it modifies
/// the current logger's handler in place without constructing a new one.
///
/// ```swift
/// let logger = Logger(label: "app")
/// await withLogger(logger) { logger in
///     logger.info("Application started")
///     await handleRequests()  // reads Logger.current
/// }
/// ```
///
/// - Parameters:
///   - logger: The logger to bind for the duration of `operation`.
///   - operation: The closure to run with `logger` bound. Receives `logger` as a
///     parameter so the body does not need to re-read ``Logger/current``.
/// - Returns: The value returned by `operation`.
```

### Sources/Logging/Logger.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/Logger.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A Logger emits log messages using methods that correspond to a log level.
///
/// `Logger` is a value type with respect to the ``Logger/Level`` and the ``Metadata`` (as well as the immutable `label`
/// and the selected ``LogHandler``).
/// Therefore, you can pass an instance of `Logger` between libraries to preserve metadata across libraries.
///
/// The most basic usage of a `Logger` is:
///
/// ```swift
/// logger.info("Hello World!")
/// ```
```

### Sources/Logging/LoggingSystem.swift:embedded-notice

Source: https://github.com/apple/swift-log/blob/4038b6a4f74a1426f47eb1dd5b4bb5628a15d597/Sources/Logging/LoggingSystem.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// The logging system is a global facility where you can configure the default logging backend implementation.
///
/// `LoggingSystem` is set up just once in a given program to set up the desired logging backend implementation.
/// The default behavior, if you don't define otherwise, sets the ``LogHandler`` to use a ``StreamLogHandler`` that presents its output to `STDOUT`.
///
/// You can configure that handler to present the output to `STDERR` instead using the following code:
///
/// ```swift
/// LoggingSystem.bootstrap(StreamLogHandler.standardError)
/// ```
///
/// The default (``StreamLogHandler``) is intended to be a convenience.
/// For production applications, implement the ``LogHandler`` protocol directly, or use a community-maintained backend.
```

## swift-nio 2.104.0

Repository: https://github.com/apple/swift-nio.git

Revision: `6db9d9abd92ad7399b8a564cafbb87d3507245fa`

### LICENSE.txt

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/LICENSE.txt

```text

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

### NOTICE.txt

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/NOTICE.txt

```text

                            The SwiftNIO Project
                            ====================

Please visit the SwiftNIO web site for more information:

  * https://github.com/apple/swift-nio

Copyright 2017, 2018 The SwiftNIO Project

The SwiftNIO Project licenses this file to you under the Apache License,
version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at:

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.

Also, please refer to each LICENSE.<component>.txt file, which is located in
the 'license' directory of the distribution file, for the license terms of the
components that this product depends on.

-------------------------------------------------------------------------------

This product is heavily influenced by Netty.

  * LICENSE (Apache License 2.0):
    * https://github.com/netty/netty/blob/4.1/LICENSE.txt
  * HOMEPAGE:
    * https://netty.io

---

This product contains NodeJS's llhttp.

  * LICENSE (MIT):
    * https://github.com/nodejs/llhttp/blob/1e1c5b43326494e97cf8244ff57475eb72a1b62c/LICENSE-MIT
  * HOMEPAGE:
    * https://github.com/nodejs/llhttp

---

This product contains "cpp_magic.h" from Thomas Nixon & Jonathan Heathcote's uSHET

  * LICENSE (MIT):
    * https://github.com/18sg/uSHET/blob/c09e0acafd86720efe42dc15c63e0cc228244c32/lib/cpp_magic.h
  * HOMEPAGE:
    * https://github.com/18sg/uSHET

---

This product contains "sha1.c" and "sha1.h" from FreeBSD (Copyright (C) 1995, 1996, 1997, and 1998 WIDE Project)

  * LICENSE (BSD-3):
    * https://opensource.org/licenses/BSD-3-Clause
  * HOMEPAGE:
    * https://github.com/freebsd/freebsd-src

---

This product contains a derivation of Fabian Fett's 'Base64.swift'.

  * LICENSE (Apache License 2.0):
    * https://github.com/swift-extras/swift-extras-base64/blob/b8af49699d59ad065b801715a5009619100245ca/LICENSE
  * HOMEPAGE:
    * https://github.com/fabianfett/swift-base64-kit

---

This product contains a derivation of "XCTest+AsyncAwait.swift" & "StructuredConcurrencyHelpers" from AsyncHTTPClient.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/swift-server/async-http-client

---

This product contains a derivation of "_TinyArray.swift" from SwiftCertificates.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/apple/swift-certificates

---

This product contains a derivation of the mocking infrastructure from Swift System.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/apple/swift-system

---

This product contains a derivation of "TokenBucket.swift" from Swift Package Manager.

  * LICENSE (Apache License 2.0):
    * https://www.apache.org/licenses/LICENSE-2.0
  * HOMEPAGE:
    * https://github.com/swiftlang/swift-package-manager
```

### Sources/CNIOAtomics/include/CNIOAtomics.h:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOAtomics/include/CNIOAtomics.h

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CNIOAtomics/src/c-atomics.c:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOAtomics/src/c-atomics.c

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CNIOFreeBSD/include/CNIOFreeBSD.h:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOFreeBSD/include/CNIOFreeBSD.h

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2026 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CNIOLLHTTP/LICENSE

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOLLHTTP/LICENSE

```text
This software is licensed under the MIT License.

Copyright Fedor Indutny, 2018.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
```

### Sources/CNIOLLHTTP/include/CNIOLLHTTP.h:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOLLHTTP/include/CNIOLLHTTP.h

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2022 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// adaptions for llhttp to make it more straightforward to use from Swift
```

### Sources/CNIOLinux/include/liburing_nio.h:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOLinux/include/liburing_nio.h

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CNIOLinux/liburing_shims.c:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOLinux/liburing_shims.c

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// Support functions for liburing

// Check if this is needed, copied from shim.c to avoid possible problems due to:
// Xcode's Archive builds with Xcode's Package support struggle with empty .c files
// (https://bugs.swift.org/browse/SR-12939).
```

### Sources/CNIOLinux/shim.c:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOLinux/shim.c

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// Xcode's Archive builds with Xcode's Package support struggle with empty .c files
// (https://bugs.swift.org/browse/SR-12939).
```

### Sources/CNIOOpenBSD/include/CNIOOpenBSD.h:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOOpenBSD/include/CNIOOpenBSD.h

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2025 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CNIOOpenBSD/shim.c:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOOpenBSD/shim.c

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2025 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// Xcode's Archive builds with Xcode's Package support struggle with empty .c files
// (https://bugs.swift.org/browse/SR-12939).
```

### Sources/CNIOPosix/event_loop_id.c:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOPosix/event_loop_id.c

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2025 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CNIOSHA1/c_nio_sha1.c:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOSHA1/c_nio_sha1.c

```text
/*-
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Copyright (C) 1995, 1996, 1997, and 1998 WIDE Project.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the project nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
```

### Sources/CNIOWASI/CNIOWASI.c:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOWASI/CNIOWASI.c

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CNIOWASI/include/CNIOWASI.h:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOWASI/include/CNIOWASI.h

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) YEARS Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/CNIOWindows/WSAStartup.c:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/CNIOWindows/WSAStartup.c

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOAsyncAwaitDemo/FullRequestResponse.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOAsyncAwaitDemo/FullRequestResponse.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// THIS FILE IS MOSTLY COPIED FROM swift-nio-extras
```

### Sources/NIOChatClient/main.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOChatClient/main.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOConcurrencyHelpers/NIOLock.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOConcurrencyHelpers/NIOLock.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2022 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOConcurrencyHelpers/NIOLockedValueBox.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOConcurrencyHelpers/NIOLockedValueBox.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2022 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Provides locked access to `Value`.
///
/// - Note: ``NIOLockedValueBox`` has reference semantics and holds the `Value`
///         alongside a lock behind a reference.
///
/// This is no different than creating a ``Lock`` and protecting all
/// accesses to a value using the lock. But it's easy to forget to actually
/// acquire/release the lock in the correct place. ``NIOLockedValueBox`` makes
/// that much easier.
```

### Sources/NIOConcurrencyHelpers/NIOThreadPoolWorkAvailable.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOConcurrencyHelpers/NIOThreadPoolWorkAvailable.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOCore/AddressedEnvelope.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/AddressedEnvelope.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A data structure for processing addressed datagrams, such as those used by UDP.
///
/// The AddressedEnvelope is used extensively on `DatagramChannel`s in order to keep track
/// of source or destination address metadata: that is, where some data came from or where
/// it is going.
```

### Sources/NIOCore/AsyncAwaitSupport.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/AsyncAwaitSupport.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOCore/AsyncChannel/AsyncChannel.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/AsyncChannel/AsyncChannel.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2022-2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Wraps a NIO ``Channel`` object into a form suitable for use in Swift Concurrency.
///
/// ``NIOAsyncChannel`` abstracts the notion of a NIO ``Channel`` into something that
/// can safely be used in a structured concurrency context. In particular, this exposes
/// the following functionality:
///
/// - reads are presented as an `AsyncSequence`
/// - writes can be written to with async functions on a writer, providing back pressure
/// - channels can be closed seamlessly
///
/// This type does not replace the full complexity of NIO's ``Channel``. In particular, it
/// does not expose the following functionality:
///
/// - user events
/// - traditional NIO back pressure such as writability signals and the channel's read call
///
/// Users are encouraged to separate their ``ChannelHandler``s into those that implement
/// protocol-specific logic (such as parsers and encoders) and those that implement business
/// logic. Protocol-specific logic should be implemented as a ``ChannelHandler``, while business
/// logic should use ``NIOAsyncChannel`` to consume and produce data to the network.
```

### Sources/NIOCore/AsyncChannel/AsyncChannelHandler.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/AsyncChannel/AsyncChannelHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2022-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOCore/AsyncChannel/AsyncChannelInboundStream.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/AsyncChannel/AsyncChannelInboundStream.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2022-2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// The inbound message asynchronous sequence of a ``NIOAsyncChannel``.
///
/// This is a unicast async sequence that allows a single iterator to be created.
```

### Sources/NIOCore/AsyncChannel/AsyncChannelOutboundWriter.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/AsyncChannel/AsyncChannelOutboundWriter.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2022-2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A ``NIOAsyncChannelOutboundWriter`` is used to write and flush new outbound messages in a channel.
///
/// The writer acts as a bridge between the Concurrency and NIO world. It allows to write and flush messages into the
/// underlying ``Channel``. Furthermore, it respects back-pressure of the channel by suspending the calls to write until
/// the channel becomes writable again.
```

### Sources/NIOCore/AsyncSequences/NIOAsyncSequenceProducer.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/AsyncSequences/NIOAsyncSequenceProducer.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2022 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOCore/BSDSocketAPI.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/BSDSocketAPI.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOCore/ByteBuffer-binaryEncodedLengthPrefix.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ByteBuffer-binaryEncodedLengthPrefix.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Describes a way to encode and decode an integer as bytes.
///
/// For more information, see <doc:ByteBuffer-lengthPrefix>
```

### Sources/NIOCore/ByteBuffer-hex.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ByteBuffer-hex.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOCore/ByteBuffer-multi-int.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ByteBuffer-multi-int.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// NOTE: THIS FILE IS AUTO-GENERATED BY dev/generate-bytebuffer-multi-int.sh
```

### Sources/NIOCore/ByteBuffer-views.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ByteBuffer-views.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A view into a portion of a `ByteBuffer`.
///
/// A `ByteBufferView` is useful whenever a `Collection where Element == UInt8` representing a portion of a
/// `ByteBuffer` is needed.
```

### Sources/NIOCore/ChannelHandler.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ChannelHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Base protocol for handlers that handle I/O events or intercept an I/O operation.
///
/// All methods are called from within the `EventLoop` that is assigned to the `Channel` itself.
///
/// You should _never_ implement this protocol directly. Please implement one of its sub-protocols.
```

### Sources/NIOCore/ChannelHandlers.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ChannelHandlers.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//  Contains ChannelHandler implementations which are generic and can be re-used easily.
//
//

/// A `ChannelHandler` that implements a backoff for a `ServerChannel` when accept produces an `IOError`.
/// These errors are often recoverable by reducing the rate at which we call accept.
```

### Sources/NIOCore/ChannelInvoker.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ChannelInvoker.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
/// Allows users to invoke an "outbound" operation related to a `Channel` that will flow through the `ChannelPipeline` until
/// it will finally be executed by the the `ChannelCore` implementation.
```

### Sources/NIOCore/ChannelOption.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ChannelOption.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A configuration option that can be set on a `Channel` to configure different behaviour.
```

### Sources/NIOCore/ChannelPipeline.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ChannelPipeline.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A list of `ChannelHandler`s that handle or intercept inbound events and outbound operations of a
/// `Channel`. `ChannelPipeline` implements an advanced form of the Intercepting Filter pattern
/// to give a user full control over how an event is handled and how the `ChannelHandler`s in a pipeline
/// interact with each other.
///
/// # Creation of a pipeline
///
/// Each `Channel` has its own `ChannelPipeline` and it is created automatically when a new `Channel` is created.
///
/// # How an event flows in a pipeline
///
/// The following diagram describes how I/O events are typically processed by `ChannelHandler`s in a `ChannelPipeline`.
/// An I/O event is handled by either a `ChannelInboundHandler` or a `ChannelOutboundHandler`
/// and is forwarded to the next handler in the `ChannelPipeline` by calling the event propagation methods defined in
/// `ChannelHandlerContext`, such as `ChannelHandlerContext.fireChannelRead` and
/// `ChannelHandlerContext.write`.
///
/// ```
///                                                    I/O Request
///                                                    via `Channel` or
///                                                    `ChannelHandlerContext`
///                                                      |
///  +---------------------------------------------------+---------------+
///  |                           ChannelPipeline         |               |
///  |                                TAIL              \|/              |
///  |    +---------------------+            +-----------+----------+    |
///  |    | Inbound Handler  N  |            | Outbound Handler  1  |    |
///  |    +----------+----------+            +-----------+----------+    |
///  |              /|\                                  |               |
///  |               |                                  \|/              |
///  |    +----------+----------+            +-----------+----------+    |
///  |    | Inbound Handler N-1 |            | Outbound Handler  2  |    |
///  |    +----------+----------+            +-----------+----------+    |
///  |              /|\                                  .               |
///  |               .                                   .               |
///  | ChannelHandlerContext.fireIN_EVT() ChannelHandlerContext.OUT_EVT()|
///  |        [ method call]                       [method call]         |
///  |               .                                   .               |
///  |               .                                  \|/              |
///  |    +----------+----------+            +-----------+----------+    |
///  |    | Inbound Handler  2  |            | Outbound Handler M-1 |    |
///  |    +----------+----------+            +-----------+----------+    |
///  |              /|\                                  |               |
///  |               |                                  \|/              |
///  |    +----------+----------+            +-----------+----------+    |
///  |    | Inbound Handler  1  |            | Outbound Handler  M  |    |
///  |    +----------+----------+            +-----------+----------+    |
///  |              /|\             HEAD                 |               |
///  +---------------+-----------------------------------+---------------+
///                  |                                  \|/
///  +---------------+-----------------------------------+---------------+
///  |               |                                   |               |
///  |       [ Socket.read ]                    [ Socket.write ]         |
///  |                                                                   |
///  |  SwiftNIO Internal I/O Threads (Transport Implementation)         |
///  +-------------------------------------------------------------------+
/// ```
///
/// An inbound event is handled by the inbound handlers in the head-to-tail direction as shown on the left side of the
/// diagram. An inbound handler usually handles the inbound data generated by the I/O thread on the bottom of the
/// diagram. The inbound data is often read from a remote peer via the actual input operation such as
/// `Socket.read`. If an inbound event goes beyond the tail inbound handler, it is discarded
/// silently, or logged if it needs your attention.
///
/// An outbound event is handled by the outbound handlers in the tail-to-head direction as shown on the right side of the
/// diagram. An outbound handler usually generates or transforms the outbound traffic such as write requests.
/// If an outbound event goes beyond the head outbound handler, it is handled by an I/O thread associated with the
/// `Channel`. The I/O thread often performs the actual output operation such as `Socket.write`.
///
///
/// For example, let us assume that we created the following pipeline:
///
/// ```
/// ChannelPipeline p = ...
/// let future = p.add(name: "1", handler: InboundHandlerA()).flatMap {
///   p.add(name: "2", handler: InboundHandlerB())
/// }.flatMap {
///   p.add(name: "3", handler: OutboundHandlerA())
/// }.flatMap {
///   p.add(name: "4", handler: OutboundHandlerB())
/// }.flatMap {
///   p.add(name: "5", handler: InboundOutboundHandlerX())
/// }
/// // Handle the future as well ....
/// ```
///
/// In the example above, a class whose name starts with `Inbound` is an inbound handler.
/// A class whose name starts with `Outbound` is an outbound handler.
///
/// In the given example configuration, the handler evaluation order is 1, 2, 3, 4, 5 when an event goes inbound.
/// When an event goes outbound, the order is 5, 4, 3, 2, 1.  On top of this principle, `ChannelPipeline` skips
/// the evaluation of certain handlers to shorten the stack depth:
///
/// - 3 and 4 don't implement `ChannelInboundHandler`, and therefore the actual evaluation order of an inbound event will be: 1, 2, and 5.
/// - 1 and 2 don't implement `ChannelOutboundHandler`, and therefore the actual evaluation order of a outbound event will be: 5, 4, and 3.
/// - If 5 implements both `ChannelInboundHandler` and `ChannelOutboundHandler`, the evaluation order of an inbound and a outbound event could be 125 and 543 respectively.
///
/// - Note: Handlers may choose not to propagate messages down the pipeline immediately.  For example a handler may need to wait
/// for additional data before sending a protocol event to the next handler in the pipeline.  Due to this you can't assume that later handlers
/// in the pipeline will receive the same number of events as were sent, or that events of different types will arrive in the same order.
/// For example - a user event could overtake a data event if a handler is aggregating data events before propagating but immediately
/// propagating user events.
///
/// # Forwarding an event to the next handler
///
/// As you might noticed in the diagram above, a handler has to invoke the event propagation methods in
/// `ChannelHandlerContext` to forward an event to its next handler.
/// Those methods include:
///
/// - Inbound event propagation methods defined in `ChannelInboundInvoker`
/// - Outbound event propagation methods defined in `ChannelOutboundInvoker`.
///
/// # Building a pipeline
///
/// A user is supposed to have one or more `ChannelHandler`s in a `ChannelPipeline` to receive I/O events (e.g. read) and
/// to request I/O operations (e.g. write and close).  For example, a typical server will have the following handlers
/// in each channel's pipeline, but your mileage may vary depending on the complexity and characteristics of the
/// protocol and business logic:
///
/// - Protocol Decoder - translates binary data (e.g. `ByteBuffer`) into a struct / class
/// - Protocol Encoder - translates a struct / class into binary data (e.g. `ByteBuffer`)
/// - Business Logic Handler - performs the actual business logic (e.g. database access)
///
/// # Thread safety
///
/// A `ChannelHandler` can be added or removed at any time because a `ChannelPipeline` is thread safe.
```

### Sources/NIOCore/CircularBuffer.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/CircularBuffer.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// An automatically expanding ring buffer implementation backed by a `ContiguousArray`. Even though this implementation
/// will automatically expand if more elements than `initialCapacity` are stored, it's advantageous to prevent
/// expansions from happening frequently. Expansions will always force an allocation and a copy to happen.
```

### Sources/NIOCore/Codec.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/Codec.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// State of the current decoding process.
```

### Sources/NIOCore/ConvenienceOptionSupport.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/ConvenienceOptionSupport.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// MARK:  Universal Client Bootstrap
```

### Sources/NIOCore/DeadChannel.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/DeadChannel.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A `DeadChannelCore` is a `ChannelCore` for a `DeadChannel`. A `DeadChannel` is used as a replacement `Channel` when
/// the original `Channel` is closed. Given that the original `Channel` is closed the `DeadChannelCore` should fail
/// all operations.
```

### Sources/NIOCore/EventLoop+SerialExecutor.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/EventLoop+SerialExecutor.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A helper protocol that can be mixed in to a NIO ``EventLoop`` to provide an
/// automatic conformance to `SerialExecutor`.
///
/// Implementers of `EventLoop` should consider conforming to this protocol as
/// well on Swift 5.9 and later.
```

### Sources/NIOCore/EventLoopFuture+AssumeIsolated.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/EventLoopFuture+AssumeIsolated.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A struct wrapping an ``EventLoop`` that ensures all calls to any method on this struct
/// are coming from the event loop.
///
/// This type is explicitly not `Sendable`. It may only be constructed on an event loop,
/// using ``EventLoop/assumeIsolated()``, and may not subsequently be passed to other isolation
/// domains.
///
/// Using this type relaxes the need to have the closures for ``EventLoop/execute(_:)``,
/// ``EventLoop/submit(_:)``, ``EventLoop/scheduleTask(in:_:)``,
/// and ``EventLoop/scheduleCallback(in:handler:)`` to be `@Sendable`.
```

### Sources/NIOCore/EventLoopFuture.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/EventLoopFuture.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOCore/IOData.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/IOData.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// `IOData` unifies standard SwiftNIO types that are raw bytes of data; currently `ByteBuffer` and `FileRegion`.
///
/// - warning: `IOData` is a legacy API, please avoid using it as much as possible.
///
/// Many `ChannelHandler`s receive or emit bytes and in most cases this can be either a `ByteBuffer` or a `FileRegion`
/// from disk. To still form a well-typed `ChannelPipeline` such handlers should receive and emit value of type `IOData`.
```

### Sources/NIOCore/IPProtocol.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/IPProtocol.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2022 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// In the Internet Protocol version 4 (IPv4) [RFC791] there is a field
/// called "Protocol" to identify the next level protocol.  This is an 8
/// bit field.  In Internet Protocol version 6 (IPv6) [RFC8200], this field
/// is called the "Next Header" field.
```

### Sources/NIOCore/IntegerBitPacking.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/IntegerBitPacking.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// FIXME: Duplicated in NIO.
```

### Sources/NIOCore/IntegerTypes.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/IntegerTypes.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// MARK: _UInt24

// FIXME: Duplicated in NIO.

/// A 24-bit unsigned integer value type.
```

### Sources/NIOCore/Linux.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/Linux.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// This is a companion to System.swift that provides only Linux specials: either things that exist
// only on Linux, or things that have Linux-specific extensions.
```

### Sources/NIOCore/MarkedCircularBuffer.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/MarkedCircularBuffer.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A circular buffer that allows one object at a time to be "marked" and easily identified and retrieved later.
///
/// This object is used extensively within SwiftNIO to handle flushable buffers. It can be used to store buffered
/// writes and mark how far through the buffer the user has flushed, and therefore how far through the buffer is
/// safe to write.
```

### Sources/NIOCore/MulticastChannel.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/MulticastChannel.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A `MulticastChannel` is a `Channel` that supports IP multicast operations: that is, a channel that can join multicast
/// groups.
///
/// - Note: As with `Channel`, all operations on a `MulticastChannel` are thread-safe.
```

### Sources/NIOCore/NIOAny.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/NIOAny.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// `NIOAny` is an opaque container for values of *any* type, similar to Swift's builtin `Any` type. Contrary to
/// `Any` the overhead of `NIOAny` depends on the the type of the wrapped value. Certain types that are important
/// for the performance of a SwiftNIO application like `ByteBuffer`, `FileRegion` and `AddressEnvelope<ByteBuffer>` can be expected
/// to be wrapped almost without overhead. All others will have similar performance as if they were passed as an `Any` as
/// `NIOAny` just like `Any` will contain them within an existential container.
///
/// The most important use-cases for `NIOAny` are values travelling through the `ChannelPipeline` whose type can't
/// be calculated at compile time. For example:
///
///  - the `channelRead` of any `ChannelInboundHandler`
///  - the `write` method of a `ChannelOutboundHandler`
///
/// The abstraction that delivers a `NIOAny` to user code must provide a mechanism to unwrap a `NIOAny` as a
/// certain type known at run-time. Canonical example:
///
///     class SandwichHandler: ChannelInboundHandler {
///         typealias InboundIn = Bacon /* we expected to be delivered `Bacon` ... */
///         typealias InboundOut = Sandwich /* ... and we will make and deliver a `Sandwich` from that */
///
///         func channelRead(context: ChannelHandlerContext, data: NIOAny) {
///              /* we receive the `Bacon` as a `NIOAny` as at compile-time the exact configuration of the channel
///                 pipeline can't be computed. The pipeline can't be computed at compile time as it can change
///                 dynamically at run-time. Yet, we assert that in any configuration the channel handler before
///                 `SandwichHandler` does actually send us a stream of `Bacon`.
///              */
///              let bacon = Self.unwrapInboundIn(data) /* `Bacon` or crash */
///              let sandwich = makeSandwich(bacon)
///              context.fireChannelRead(Self.wrapInboundOut(sandwich)) /* as promised we deliver a wrapped `Sandwich` */
///         }
///     }
```

### Sources/NIOCore/NIOCloseOnErrorHandler.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/NIOCloseOnErrorHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A `ChannelInboundHandler` that closes the channel when an error is caught
```

### Sources/NIOCore/NIOLoopBound.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/NIOLoopBound.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// ``NIOLoopBound`` is an always-`Sendable`, value-typed container allowing you access to ``value`` if and only if
/// you are accessing it on the right ``EventLoop``.
///
/// ``NIOLoopBound`` is useful to transport a value of a non-`Sendable` type that needs to go from one place in
/// your code to another where you (but not the compiler) know is on one and the same ``EventLoop``. Usually this
/// involves `@Sendable` closures. This type is safe because it verifies (using ``EventLoop/preconditionInEventLoop(file:line:)-2fxvb``)
/// that this is actually true.
///
/// A ``NIOLoopBound`` can only be constructed, read from or written to when you are provably
/// (through ``EventLoop/preconditionInEventLoop(file:line:)-2fxvb``) on the ``EventLoop`` associated with the ``NIOLoopBound``. Accessing
/// or constructing it from any other place will crash your program with a precondition as it would be undefined
/// behaviour to do so.
```

### Sources/NIOCore/NIOPooledRecvBufferAllocator.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/NIOPooledRecvBufferAllocator.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A receive buffer allocator which cycles through a pool of buffers.
///
/// Channels can read multiple times per cycle (based on `ChannelOptions.maxMessagesPerRead`), and they reuse
/// the inbound buffer for each read. If a `ChannelHandler` holds onto this buffer, then CoWing will be needed.
/// A `NIOPooledRecvBufferAllocator` cycles through preallocated buffers to avoid CoWs during the same read cycle.
```

### Sources/NIOCore/NIOScheduledCallback.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/NIOScheduledCallback.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A type that handles callbacks scheduled with `EventLoop.scheduleCallback(at:handler:)`.
///
/// - Seealso: `EventLoop.scheduleCallback(at:handler:)`.
```

### Sources/NIOCore/NIOTransportAccessibleChannelCore.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/NIOTransportAccessibleChannelCore.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A ``ChannelCore`` that provides access to its underlying transport.
///
/// This API is only used for ``Channel`` implementations: if you are not implementing a ``Channel``, do not use this
/// protocol directly. Instead use ``ChannelPipeline/SynchronousOperations/withUnsafeTransportIfAvailable(of:_:)``.
///
/// Not all channels are expected to conform to ``NIOTransportAccessibleChannelCore``, but this is determined at runtime, by
/// ``ChannelPipeline/SynchronousOperations/withUnsafeTransportIfAvailable(of:_:)``.
```

### Sources/NIOCore/RecvByteBufferAllocator.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/RecvByteBufferAllocator.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Allocates `ByteBuffer`s to be used to read bytes from a `Channel` and records the number of the actual bytes that were used.
```

### Sources/NIOCore/SingleStepByteToMessageDecoder.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/SingleStepByteToMessageDecoder.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A simplified version of `ByteToMessageDecoder` that can generate zero or one messages for each invocation of `decode` or `decodeLast`.
/// Having `decode` and `decodeLast` return an optional message avoids re-entrancy problems, since the functions relinquish exclusive access
/// to the `ByteBuffer` when returning. This allows for greatly simplified processing.
///
/// Many `ByteToMessageDecoder`'s can trivially be translated to `NIOSingleStepByteToMessageDecoder`'s. You should not implement
/// `ByteToMessageDecoder`'s `decode` and `decodeLast` methods.
```

### Sources/NIOCore/SystemCallHelpers.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/SystemCallHelpers.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//  This file contains code that ensures errno is captured correctly when doing syscalls and no ARC traffic can happen inbetween that *could* change the errno
//  value before we were able to read it.
//  It's important that all static methods are declared with `@inline(never)` so it's not possible any ARC traffic happens while we need to read errno.
//
//  Created by Norman Maurer on 11/10/17.
//
// This file arguably shouldn't be here in NIOCore, but due to early design decisions we accidentally exposed a few types that
// know about system calls into the core API (looking at you, FileHandle). As a result we need support for a small number of system calls.
```

### Sources/NIOCore/TypeAssistedChannelHandler.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/TypeAssistedChannelHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// ChannelHandler which will emit data by calling `ChannelHandlerContext.write`.
///
/// We _strongly_ advice against implementing this protocol directly. Please implement `ChannelInboundHandler` or / and `ChannelOutboundHandler`.
```

### Sources/NIOCore/UniversalBootstrapSupport.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/UniversalBootstrapSupport.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// `NIOClientTCPBootstrapProtocol` is implemented by various underlying transport mechanisms. Typically,
/// this will be the BSD Sockets API implemented by `ClientBootstrap`.
```

### Sources/NIOCore/Utilities.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOCore/Utilities.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021-2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOFS/ByteCount.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOFS/ByteCount.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Represents the number of bytes.
```

### Sources/NIOFS/Exports.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOFS/Exports.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// These types are used in our public API; expose them to make
// life easier for users.
```

### Sources/NIOFS/IOStrategy.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOFS/IOStrategy.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// How many file descriptors to open when performing I/O operations.
```

### Sources/NIOFS/Internal/Concurrency Primitives/TokenBucket.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOFS/Internal/Concurrency Primitives/TokenBucket.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOFS/Internal/System Calls/Mocking.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOFS/Internal/System Calls/Mocking.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// This source file is part of the Swift System open source project//
// Copyright (c) 2020 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception//
// See https://swift.org/LICENSE.txt for license information
```

### Sources/NIOFoundationEssentialsCompat/Codable+ByteBuffer.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOFoundationEssentialsCompat/Codable+ByteBuffer.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOHTTP1/NIOHTTPClientUpgradeHandler.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOHTTP1/NIOHTTPClientUpgradeHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOHTTP1/NIOTypedHTTPServerUpgradeHandler.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOHTTP1/NIOTypedHTTPServerUpgradeHandler.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOPerformanceTester/Benchmark.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOPerformanceTester/Benchmark.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOPerformanceTester/TCPThroughputBenchmark.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOPerformanceTester/TCPThroughputBenchmark.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOPerformanceTester/main.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOPerformanceTester/main.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// swift-format-ignore: AmbiguousTrailingClosureOverload

// swift-format-ignore: OrderedImports
// Required due to https://github.com/swiftlang/swift/issues/76842
```

### Sources/NIOPerformanceTester/resources.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOPerformanceTester/resources.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// generated using:
//     curl -s https://swift.org/ | iconv -c -f utf-8 -t ascii | pbcopy
```

### Sources/NIOPosix/BSDSocketAPICommon.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOPosix/BSDSocketAPICommon.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOPosix/SelectorUring.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOPosix/SelectorUring.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOPosix/StructuredConcurrencyHelpers.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOPosix/StructuredConcurrencyHelpers.swift

```text

//===----------------------------------------------------------------------===//
//
// This source file is part of the AsyncHTTPClient open source project
//
// Copyright (c) 2025 Apple Inc. and the AsyncHTTPClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of AsyncHTTPClient project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOPosix/System.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOPosix/System.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2024 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//  This file contains code that ensures errno is captured correctly when doing syscalls and no ARC traffic can happen inbetween that *could* change the errno
//  value before we were able to read it.
//  It's important that all static methods are declared with `@inline(never)` so it's not possible any ARC traffic happens while we need to read errno.
```

### Sources/NIOPosix/Thread.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/NIOPosix/Thread.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2014 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/_NIOBase64/Base64.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/_NIOBase64/Base64.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// This is a simplified vendored version from:
// https://github.com/fabianfett/swift-base64-kit
```

### Sources/_NIOConcurrency/Empty.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/_NIOConcurrency/Empty.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// NOTE: All the helper methods that where located here, have been moved to NIOCore. This module
//       only exists to not break adopters code for now. Please remove all your dependencies on
//       `_NIOConcurrency`. We want to remove this module soon.
```

### Sources/_NIODataStructures/_TinyArray.swift:embedded-notice

Source: https://github.com/apple/swift-nio/blob/6db9d9abd92ad7399b8a564cafbb87d3507245fa/Sources/_NIODataStructures/_TinyArray.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftCertificates open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftCertificates project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftCertificates project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// ``TinyArray`` is a ``RandomAccessCollection`` optimised to store zero or one ``Element``.
/// It supports arbitrary many elements but if only up to one ``Element`` is stored it does **not** allocate separate storage on the heap
/// and instead stores the ``Element`` inline.
```

## swift-nio-ssh 0.3.7 + MARC security backport 1

Repository: https://github.com/Wellz26/swift-nio-ssh.git

Revision: `d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c`

### LICENSE.txt

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/LICENSE.txt

```text

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

### Sources/NIOSSH/ByteBuffer+SSH.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/ByteBuffer+SSH.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOSSH/CSPRNG/CSPRNG.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/CSPRNG/CSPRNG.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A cryptographically secure random number generator.
///
/// SSH has a number of use-cases where we require a number of random bytes suitable
/// for use in cryptographic contexts. In this case, we want to defer to the system's
/// best available resource for these bytes. This object wraps those calls.
///
/// In an ideal world we'd be using something from Swift here, perhaps
/// `SystemRandomNumberGenerator`. However there is uncertainty about whether
/// `SystemRandomNumberGenerator` is actually suitable for use as a CSPRNG on all platforms:
/// see https://forums.swift.org/t/clarify-the-cryptographic-properties-of-systemrandomnumbergenerator/27249
/// for more details.
///
/// We feel confident that the `SystemRandomNumberGenerator` will remain a CSPRNG on all Apple platforms
/// and on Linux for the foreseeable future. This CSPRNG therefore wraps the `SystemRandomNumberGenerator`
/// on those platforms, and traps on all others.
```

### Sources/NIOSSH/Child Channels/ChildChannelOptions.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Child Channels/ChildChannelOptions.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOSSH/Child Channels/ChildChannelStateMachine.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Child Channels/ChildChannelStateMachine.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A state machine that manages the state of child channels.
///
/// Child channels move through a weird set of states, because they can "exist" before the protocol is aware of them. In particular, there
/// are a few strange states that don't correspond to what the wire protocol looks like.
```

### Sources/NIOSSH/Child Channels/ChildChannelWritabilityManager.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Child Channels/ChildChannelWritabilityManager.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// The outbound flow control manager for `SSHChildChannel` objects.
///
/// Our flow control strategy here is in two parts. The first is a watermarked
/// pending-byte-based flow control strategy that uses the number of writes that have been
/// issued by the channel but not written to the network. If these writes move past a certain
/// threshold, the channel writability state will change.
///
/// The second is a parent-channel based observation. If the parent channel is not writable,
/// there is no reason to tell the stream channels that they can write either, as those writes
/// will simply back up in the parent.
///
/// The observed effect is that the `SSHChildChannel` is writable only if both of the above
/// strategies are writable: if either is not writable, neither is the `SSHChildChannel`.
```

### Sources/NIOSSH/Child Channels/OutboundFlowController.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Child Channels/OutboundFlowController.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Keeps track of whether or not a `Channel` should be able to write based on flow control windows.
```

### Sources/NIOSSH/Child Channels/SSHChannelIdentifier.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Child Channels/SSHChannelIdentifier.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// The identifier for a single SSH channel.
///
/// An SSH channel is identified by a number on each end of the connection. These two numbers are not required
/// to be the same, nor are they required to be chosen in any specific way. The only requirement is that they are
/// unique within the same ID space (that is, a single peer may not re-use a channel ID while that ID is still live).
///
/// Channels can exist in a "local-only" state where they have not yet been accepted by a remote peer. In NIOSSH we
/// don't allow channels in this state to have a formal channel identifier yet: they simply have a provisional local
/// channel ID.
```

### Sources/NIOSSH/Connection State Machine/Operations/AcceptsChannelMessages.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Connection State Machine/Operations/AcceptsChannelMessages.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// A protocol for states that accept channel messages.
```

### Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Connection State Machine/SSHConnectionStateMachine.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOSSH/Keys And Signatures/CustomKeys.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Keys And Signatures/CustomKeys.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2022 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### Sources/NIOSSH/NIOSSHError.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/NIOSSHError.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// An error thrown by NIOSSH.
///
/// For extensibility purposes, ``NIOSSHError``s are composed of two parts. The first part is an
/// error type. This is like an enum, but extensible, and identifies the kind of error programmatically.
/// The second part is some opaque diagnostic data. This is not visible to your code, but is used to
/// help provide extra information for diagnostic purposes when logging this error.
///
/// Note that due to this construction ``NIOSSHError`` is not equatable: only the ``NIOSSHError/type`` is. This is deliberate,
/// as it is possible two errors have the same type but a different underlying cause or diagnostic data. For
/// this reason, if you need to compare two ``NIOSSHError`` values you should explicitly compare their ``NIOSSHError/type``.
```

### Sources/NIOSSH/Role.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/Role.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// The role of a given party in an SSH connection.
```

### Sources/NIOSSH/SSHClientConfiguration.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/SSHClientConfiguration.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Configuration for an SSH client.
```

### Sources/NIOSSH/SSHServerConfiguration.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSH/SSHServerConfiguration.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2020 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// Configuration for an SSH server.
```

### Sources/NIOSSHPerformanceTester/BenchmarkLinearThroughput.swift:embedded-notice

Source: https://github.com/Wellz26/swift-nio-ssh/blob/d88989f3d3bb1dfb2a38ce4af598afbf7fc3095c/Sources/NIOSSHPerformanceTester/BenchmarkLinearThroughput.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
```

### MARC local modifications

Source: Vendor/swift-nio-ssh/MARC_MODIFICATIONS.md

```text
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

Swift Crypto is pinned to 5.0.3 to include the upstream RSA key-parsing and
VOPRF input-length fixes. This dependency change is additional to the upstream
base snapshot; the SSH ECDSA parser backport remains in place.
```

## swift-png 4.5.1

Repository: https://github.com/tayloraswift/swift-png

Revision: `8a0bcd4df5e4b307c804937776a56dd6ecdf6396`

### LICENSE

Source: https://github.com/tayloraswift/swift-png/blob/8a0bcd4df5e4b307c804937776a56dd6ecdf6396/LICENSE

```text

                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright 2026
   Diana Ma (@tayloraswift)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

### NOTICE

Source: https://github.com/tayloraswift/swift-png/blob/8a0bcd4df5e4b307c804937776a56dd6ecdf6396/NOTICE

```text
the `swift-png` package was created by diana ma (@tayloraswift).

you are welcome to contribute to this project at:

    https://github.com/tayloraswift/swift-png

we do not maintain any other mirrors of this repository, and such
forks of this repository may not carry the most up-to-date code.
```

## swift-system 1.8.1

Repository: https://github.com/apple/swift-system.git

Revision: `869129b7bf4ecc57b97d0193ad29690ca2134750`

### LICENSE.txt

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/LICENSE.txt

```text
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

    1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

    2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

    3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

    4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

    5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

    6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

    7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

    8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

    9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

    END OF TERMS AND CONDITIONS

    APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

    Copyright [yyyy] [name of copyright owner]

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.



## Runtime Library Exception to the Apache 2.0 License: ##


    As an exception, if you use this Software to compile your source code and
    portions of this Software are embedded into the binary product as a result,
    you may redistribute such product without providing attribution as would
    otherwise be required by Sections 4(a), 4(b) and 4(d) of the License.
```

### Sources/CSystem/include/CSystemDarwin.h:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/CSystem/include/CSystemDarwin.h

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/
```

### Sources/CSystem/include/CSystemLinux.h:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/CSystem/include/CSystemLinux.h

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/
```

### Sources/CSystem/include/CSystemWASI.h:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/CSystem/include/CSystemWASI.h

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/
```

### Sources/CSystem/shims.c:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/CSystem/shims.c

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/
```

### Sources/System/Errno.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/Errno.swift

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/
```

### Sources/System/ErrnoWindows.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/ErrnoWindows.swift

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/
```

### Sources/System/FilePath/FilePathTempPosix.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/FilePath/FilePathTempPosix.swift

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2024 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */
```

### Sources/System/FileSystem/FileFlags.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/FileSystem/FileFlags.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// |------------------------|
// | Swift API to C Mapping |
// |------------------------------------------------------------------|
// | FileFlags        | Darwin        | FreeBSD       | OpenBSD       |
// |------------------|---------------|---------------|---------------|
// | noDump           | UF_NODUMP     | UF_NODUMP     | UF_NODUMP     |
// | userImmutable    | UF_IMMUTABLE  | UF_IMMUTABLE  | UF_IMMUTABLE  |
// | userAppend       | UF_APPEND     | UF_APPEND     | UF_APPEND     |
// | archived         | SF_ARCHIVED   | SF_ARCHIVED   | SF_ARCHIVED   |
// | systemImmutable  | SF_IMMUTABLE  | SF_IMMUTABLE  | SF_IMMUTABLE  |
// | systemAppend     | SF_APPEND     | SF_APPEND     | SF_APPEND     |
// | opaque           | UF_OPAQUE     | UF_OPAQUE     | N/A           |
// | hidden           | UF_HIDDEN     | UF_HIDDEN     | N/A           |
// | systemNoUnlink   | SF_NOUNLINK   | SF_NOUNLINK   | N/A           |
// | compressed       | UF_COMPRESSED | N/A           | N/A           |
// | tracked          | UF_TRACKED    | N/A           | N/A           |
// | dataVault        | UF_DATAVAULT  | N/A           | N/A           |
// | restricted       | SF_RESTRICTED | N/A           | N/A           |
// | firmlink         | SF_FIRMLINK   | N/A           | N/A           |
// | dataless         | SF_DATALESS   | N/A           | N/A           |
// | userNoUnlink     | N/A           | UF_NOUNLINK   | N/A           |
// | offline          | N/A           | UF_OFFLINE    | N/A           |
// | readOnly         | N/A           | UF_READONLY   | N/A           |
// | reparse          | N/A           | UF_REPARSE    | N/A           |
// | sparse           | N/A           | UF_SPARSE     | N/A           |
// | system           | N/A           | UF_SYSTEM     | N/A           |
// | snapshot         | N/A           | SF_SNAPSHOT   | N/A           |
// |------------------|---------------|---------------|---------------|
```

### Sources/System/FileSystem/FileMode.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/FileSystem/FileMode.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//
```

### Sources/System/FileSystem/FileType.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/FileSystem/FileType.swift

```text
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift System open source project
//
// Copyright (c) 2025 - 2026 Apple Inc. and the Swift System project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// |------------------------|
// | Swift API to C Mapping |
// |----------------------------------------|
// | FileType         | Unix-like Platforms |
// |------------------|---------------------|
// | directory        | S_IFDIR             |
// | characterSpecial | S_IFCHR             |
// | blockSpecial     | S_IFBLK             |
// | regular          | S_IFREG             |
// | fifo             | S_IFIFO             |
// | symbolicLink     | S_IFLNK             |
// | socket           | S_IFSOCK            |
// |------------------|---------------------|
//
// |------------------------------------------------------------------|
// | FileType         | Darwin  | FreeBSD | Other Unix-like Platforms |
// |------------------|---------|---------|---------------------------|
// | whiteout         | S_IFWHT | S_IFWHT | N/A                       |
// |------------------|---------|---------|---------------------------|
```

### Sources/System/Internals/Backcompat.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/Internals/Backcompat.swift

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/
```

### Sources/System/Internals/CInterop.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/Internals/CInterop.swift

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2026 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 */
```

### Sources/System/MachPort.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/MachPort.swift

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2022 - 2025 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/
```

### Sources/System/Util.swift:embedded-notice

Source: https://github.com/apple/swift-system/blob/869129b7bf4ecc57b97d0193ad29690ca2134750/Sources/System/Util.swift

```text
/*
 This source file is part of the Swift System open source project

 Copyright (c) 2020 - 2021 Apple Inc. and the Swift System project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
*/
```

## SwiftTerm 1.99.0

Repository: https://github.com/migueldeicaza/SwiftTerm.git

Revision: `2dad6a1e516f755bed77cf9bbd09455062f54758`

### LICENSE

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/LICENSE

```text
Copyright (c) 2019-2026 Miguel de Icaza (https://github.com/migueldeicaza)
Copyright (c) 2017-2019, The xterm.js authors (https://github.com/xtermjs/xterm.js)
Copyright (c) 2014-2016, SourceLair Private Company (https://www.sourcelair.com)
Copyright (c) 2012-2013, Christopher Jeffrey (https://github.com/chjj/)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

### Sources/SwiftTerm/Buffer.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/Buffer.swift

```text
//
//  Buffer.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/26/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
```

### Sources/SwiftTerm/BufferLine.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/BufferLine.swift

```text
//
//  BufferLine.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/26/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
```

### Sources/SwiftTerm/CharData.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/CharData.swift

```text
//
//  CharData.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/19/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
```

### Sources/SwiftTerm/CharSets.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/CharSets.swift

```text
//
//  CharSets.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/1/20.
//  Copyright © 2020 Miguel de Icaza. All rights reserved.
//
```

### Sources/SwiftTerm/CircularList.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/CircularList.swift

```text
//
//  CircularList.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/25/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
```

### Sources/SwiftTerm/Colors.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/Colors.swift

```text
//
//  Colors.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/1/20.
//  Copyright © 2020 Miguel de Icaza. All rights reserved.
//
```

### Sources/SwiftTerm/EscapeSequenceParser.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/EscapeSequenceParser.swift

```text
//
//  EscapeSequenceParser.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/28/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
// The state machien has been extended to allow ":" in the CSI Param state to initiate a new
// parameter value.   This is strictly not part of the spec, but necessary to parse the
// color scheme CSI [ 48:2:R:G:B m sequence which uses ":" instead of the more common ";"
//
// Alternative approaches:
//   * only allow ":" as a CsiParam if the first param is a 48/38.
//   * create an additiona "ignoredBuffer" that is passed to functions interested in those,
//     and this could be one of those.   Would be a little stricter, and probably better
```

### Sources/SwiftTerm/EscapeSequences.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/EscapeSequences.swift

```text
//
//  EscapeSequences.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/30/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
```

### Sources/SwiftTerm/SelectionService.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/SelectionService.swift

```text
//
//  SelectionService.swift
//  iOS
//
//  Created by Miguel de Icaza on 3/5/20.
//  Copyright © 2020 Miguel de Icaza. All rights reserved.
//
```

### Sources/SwiftTerm/Terminal.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/Terminal.swift

```text
//
//  Terminal.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/27/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//
// TODO: review every place that sets cursor to use setCursor
// TODO: audit every location to use restrictCursor
```

### Sources/SwiftTerm/TerminalOptions.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/TerminalOptions.swift

```text
//
//  TerminalOptions.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 2/29/20.
//  Copyright © 2020 Miguel de Icaza. All rights reserved.
//
```

### Sources/SwiftTerm/Utilities.swift:embedded-notice

Source: https://github.com/migueldeicaza/SwiftTerm/blob/2dad6a1e516f755bed77cf9bbd09455062f54758/Sources/SwiftTerm/Utilities.swift

```text
//
//  Utilities.swift
//  SwiftTerm
//
//  Created by Miguel de Icaza on 3/4/20.
//  Copyright © 2020 Miguel de Icaza. All rights reserved.
//
```
