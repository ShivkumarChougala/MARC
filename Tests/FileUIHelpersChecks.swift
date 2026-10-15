import Foundation

@main
struct FileUIHelpersChecks {
    static func main() {
        precondition(MARCFileFormatting.permissions(0o100644) == "-rw-r--r--")
        precondition(MARCFileFormatting.permissions(0o040777) == "drwxrwxrwx")
        precondition(MARCFileFormatting.permissions(0o120777) == "lrwxrwxrwx")
        precondition(MARCFileFormatting.permissions(0o104755) == "-rwsr-xr-x")
        precondition(MARCFileFormatting.permissions(0o041700) == "drwx-----T")
        precondition(MARCFileFormatting.permissions(nil) == "Permissions unavailable")
        precondition(MARCFileFormatting.shellDirectoryCommand("/tmp/a'b") == "cd -- '/tmp/a'\"'\"'b'")
        precondition(MARCFileFormatting.shellDirectoryCommand("/tmp/$(touch marker)") == "cd -- '/tmp/$(touch marker)'")
        precondition(MARCFileFormatting.shellDirectoryCommand("/tmp/bad\nname") == nil)
        precondition(MARCFileFormatting.shellDirectoryCommand("relative") == nil)
        precondition(MARCTerminalInput.modified([99], control: true, alt: false) == [3])
        precondition(MARCTerminalInput.modified([67], control: true, alt: false) == [3])
        precondition(MARCTerminalInput.modified([97], control: false, alt: true) == [27, 97])
        precondition(MARCTerminalInput.modified([99], control: true, alt: true) == [27, 3])
        precondition(MARCTerminalInput.modified([], control: true, alt: true).isEmpty)
        print("PASS: permission labels, shell quoting, control-character rejection and Ctrl/Alt key bytes")
    }
}
