import Foundation

/// Local teaching copy; never performs an action on the connected Mac.
enum MARCLearningHint: String, CaseIterable {
    case status, statusSystem, processes, files, filesFolders, filesActions, systemCPU, systemMemory, systemStorage, controls, terminal

    var preferenceKey: String { "marc.learn.v1." + rawValue }
    var title: String {
        switch self {
        case .status: return "See the bigger picture"
        case .statusSystem: return "Take a closer look"
        case .processes: return "Find what’s slowing things down"
        case .files: return "Send a file to this folder"
        case .filesFolders: return "Find your way around"
        case .filesActions: return "More than a filename"
        case .systemCPU: return "See where the work is happening"
        case .systemMemory: return "Understand your Mac’s memory"
        case .systemStorage: return "Space and activity are different"
        case .controls: return "Keep your favourite apps close"
        case .terminal: return "A little help at the prompt"
        }
    }
    var message: String {
        switch self {
        case .status: return "Open Statistics to see how your Mac’s usage changes over time."
        case .statusSystem: return "Open System for CPU, memory, network, storage and battery details where available."
        case .processes: return "Choose CPU for the busiest apps, or Memory for the biggest users. Tap a row to review it before ending a process."
        case .files: return "Choose Files or Photos & Videos from Upload. An existing filename gives you Replace or Cancel."
        case .filesFolders: return "Tap the folder name to jump to a parent folder. Back goes up one level; Home takes you to your account’s home folder."
        case .filesActions: return "Tap an item’s three dots for Download, Rename or move, Permissions and more. Delete always asks you to confirm."
        case .systemCPU: return "SYS and USER split CPU usage between system work and apps. Each bar below shows a core; warmer colours mean higher usage."
        case .systemMemory: return "Used is memory currently in use. Available is an estimate; Swap is disk space used to support memory."
        case .systemStorage: return "Available shows free capacity. Read and Write show disk activity, not how much storage your files occupy."
        case .controls: return "Use Edit to choose Quick Launch apps for this Mac. Tap an app to open it on your Mac."
        case .terminal: return "Choose Local or API in Settings → Terminal & AI. Ask here, then review a suggested command before choosing Run."
        }
    }

    static func next(in hints: [Self], dismissed: Set<String>, visible: Set<String>) -> Self? {
        hints.first { !dismissed.contains($0.rawValue) && visible.contains($0.rawValue) }
    }

    static func canPresent(dismissed: Bool, enabled: Bool, active: Bool,
                           setupActive: Bool, blocked: Bool, keyboardVisible: Bool) -> Bool {
        !dismissed && enabled && active && !setupActive && !blocked && !keyboardVisible
    }
}
