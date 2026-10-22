import Foundation

/// Text/transport validation only. This does not establish shell state or
/// determine whether a command is safe to execute.
nonisolated enum MARCAICommandSafety {
    static let maximumBytes = 8192

    static func hasHiddenFormatting(_ text: String) -> Bool {
        text.unicodeScalars.contains {
            $0.properties.isDefaultIgnorableCodePoint || $0.properties.isBidiControl ||
                $0.properties.generalCategory == .format
        }
    }

    static func validated(_ text: String) -> String? {
        guard !text.isEmpty, text.utf8.count <= maximumBytes else { return nil }
        for scalar in text.unicodeScalars {
            let properties = scalar.properties
            if properties.isDefaultIgnorableCodePoint || properties.isBidiControl ||
                properties.isNoncharacterCodePoint { return nil }
            switch properties.generalCategory {
            case .control, .format, .lineSeparator, .paragraphSeparator:
                return nil
            default:
                break
            }
        }
        // Trim plain spaces only, so edge control/format characters are never
        // silently removed before validation. Preserve Unicode filenames exactly.
        let value = text.trimmingCharacters(in: CharacterSet(charactersIn: " "))
        return value.isEmpty ? nil : value
    }
}
