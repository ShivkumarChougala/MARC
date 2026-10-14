import Foundation

guard CommandLine.arguments.count == 2 else {
    fatalError("Usage: verify-plist.swift /path/to/MARC.app/Info.plist")
}
let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
guard let dictionary = plist as? [String: Any],
      let services = dictionary["NSBonjourServices"] as? [String],
      services == ["_ssh._tcp"],
      let description = dictionary["NSLocalNetworkUsageDescription"] as? String,
      !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
    fatalError("FAIL: generated Info.plist must contain NSBonjourServices as an array with _ssh._tcp and a Local Network explanation")
}
print("PASS: generated Info.plist NSBonjourServices = \(services), Local Network explanation present")
