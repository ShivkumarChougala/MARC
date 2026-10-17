import Foundation

enum MARCSystemDetailsData {
    enum CoreLevel { case normal, elevated, high, unavailable }

    static func coreLevel(_ usage: Double) -> CoreLevel {
        guard usage.isFinite else { return .unavailable }
        if usage >= 85 { return .high }
        if usage >= 70 { return .elevated }
        return .normal
    }

    static func batteryStatus(state: String?, source: String?) -> String {
        switch state?.lowercased() {
        case "charging": return "Charging"
        case "charged": return "Fully charged"
        case "discharging": return "On battery"
        case "finishing charge": return "Finishing charge"
        case "not charging": return "Not charging"
        default:
            if source == "AC Power" { return "Power adapter" }
            if source == "Battery Power" { return "On battery" }
            return "Unavailable"
        }
    }

}
