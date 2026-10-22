import Foundation

@main
struct AICommandSafetyChecks {
    static func main() {
        let valid = ["pwd", "ls -la", "  printf '%s' 'hello world'  ",
                     "cat 'résumé.txt'", "ls 'ನಮಸ್ಕಾರ'", "cat '日本語.txt'",
                     "printf '%s' 'e\u{0301}'", "echo '🚀'", "echo 'مرحبا'",
                     "printf '%s' '\\n'", "printf '%s' '\\u202e'", "echo a && echo b"]
        for command in valid {
            guard let result = MARCAICommandSafety.validated(command) else {
                preconditionFailure("Visible command incorrectly blocked")
            }
            precondition(!result.utf8.contains(10) && !result.utf8.contains(13))
            precondition(result == command.trimmingCharacters(in: CharacterSet(charactersIn: " ")),
                         "Unicode text and literal escapes must remain unchanged")
        }
        for scalar in Array(UInt32(0)...31) + Array(UInt32(127)...159) {
            precondition(MARCAICommandSafety.validated("echo a" + String(UnicodeScalar(scalar)!) + "b") == nil,
                         "Control characters must not enter the terminal")
        }
        let hidden: [UInt32] = [0xAD, 0x34F, 0x61C, 0x115F, 0x1160, 0x17B4, 0x17B5,
                               0x180E, 0x200B, 0x200C, 0x200D, 0x200E, 0x200F,
                               0x202A, 0x202B, 0x202C, 0x202D, 0x202E,
                               0x2060, 0x2066, 0x2067, 0x2068, 0x2069,
                               0xFE00, 0xFE0F, 0xFEFF, 0xE0001, 0xE0020, 0xE0100]
        for value in hidden {
            let scalar = String(UnicodeScalar(value)!)
            for command in [scalar + "pwd", "p" + scalar + "wd", "pwd" + scalar] {
                precondition(MARCAICommandSafety.validated(command) == nil,
                             "Invisible or directional formatting must be rejected")
                precondition(MARCAICommandSafety.hasHiddenFormatting(command))
            }
        }
        for command in ["", "   ", "pwd\nwhoami", "pwd\r", "\tpwd", "pwd\u{2028}whoami",
                        "pwd\u{2029}whoami", "echo \u{FFFF}", "echo \u{10FFFF}"] {
            precondition(MARCAICommandSafety.validated(command) == nil)
        }
        precondition(MARCAICommandSafety.validated(String(repeating: "a", count: 8192)) != nil)
        precondition(MARCAICommandSafety.validated(String(repeating: "a", count: 8193)) == nil)
        precondition(MARCAICommandSafety.validated(String(repeating: "é", count: 4096)) != nil)
        precondition(MARCAICommandSafety.validated(String(repeating: "é", count: 4097)) == nil)
        // Text validation deliberately does not claim to classify shell semantics.
        precondition(MARCAICommandSafety.validated("rm -rf /tmp/disposable-fixture") != nil)
        print("PASS: AI command text rejects controls, hidden/bidirectional formatting, line separators and oversized UTF-8; visible Unicode is preserved")
    }
}
