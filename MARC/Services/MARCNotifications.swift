import Foundation
import Observation
import UIKit
import UserNotifications

/// Local event delivery only. This service never extends SSH background runtime.
@MainActor @Observable final class MARCNotifications: NSObject, UNUserNotificationCenterDelegate {
    static let shared = MARCNotifications()
    struct Destination: Equatable {
        let serverID: UUID
        let tab: Int
    }
    let ruleStore = MARCAlertStore()
    @ObservationIgnored private var ruleEngine = MARCAlertEngine()
    @ObservationIgnored private var eligibleCustom = Set<String>()
    @ObservationIgnored private var observingLifecycle = false
    @ObservationIgnored private var observedRuleChange: UUID?
    @ObservationIgnored private var deliveryEpoch = UUID()
    private var cooldownMinutes: Int {
        let value = defaults.object(forKey: "marc.notifications.cooldownMinutes") as? Int ?? 60
        return MARCAlertRule.cooldownOptions.contains(value) ? value : 60
    }
    private var repeatMinutes: Int {
        let value = defaults.integer(forKey: "marc.notifications.repeatMinutes")
        return MARCAlertRule.repeatOptions.contains(value) ? value : 0
    }
    func preferencesChanged() { resetRuleIntervals() }
    var destination: Destination?
    private(set) var authorized = false
    private(set) var denied = false
    private(set) var failure: String?
    @ObservationIgnored private let center = UNUserNotificationCenter.current()
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var pending = Set<String>()

    func start() {
        defaults.register(defaults: ["marc.notifications.transfers": true])
        // Changing preset policy must not inherit a latch from an old user-selected limit.
        // Keep last-sent times so the existing cooldown still protects against repeat alerts.
        if defaults.integer(forKey: "marc.notifications.standardPolicyVersion") < 1 {
            for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("marc.notifications.state.") {
                if key.hasSuffix(".latched") || key.hasSuffix(".recoveryPending") {
                    defaults.removeObject(forKey: key)
                }
            }
            defaults.set(1, forKey: "marc.notifications.standardPolicyVersion")
        }
        center.delegate = self
        if let data = defaults.data(forKey: "marc.notifications.deliveries.v1"),
           let deliveries = try? JSONDecoder().decode([String: MARCAlertEngine.Delivery].self, from: data) {
            ruleEngine.deliveries = deliveries
        }
        if !observingLifecycle {
            observingLifecycle = true
            NotificationCenter.default.addObserver(self, selector: #selector(resetRuleIntervals),
                name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(resetRuleIntervals),
                name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        Task { await refreshAuthorization() }
    }

    func refreshAuthorization() async {
        let settings = await center.notificationSettings()
        authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        denied = settings.authorizationStatus == .denied
    }

    func enable() async {
        failure = nil
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            defaults.set(granted, forKey: "marc.notifications.enabled")
        } catch {
            failure = "Notification permission could not be requested. Try again in iOS Settings."
        }
        await refreshAuthorization()
    }

    func disable() {
        defaults.set(false, forKey: "marc.notifications.enabled")
        resetRuleIntervals()
        // MARC currently owns only local notifications.
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    /// Tests local iPhone delivery without a Mac sample or changes to alert incident state.
    func scheduleTestNotification(rule: MARCAlertRule? = nil) async -> Bool {
        failure = nil
        await refreshAuthorization()
        guard authorized, defaults.bool(forKey: "marc.notifications.enabled") else {
            failure = "Enable notifications before sending a test."
            return false
        }
        if let rule, !rule.isValid {
            failure = "Finish setting up the alert before sending a test."
            return false
        }
        let id = "marc.notifications.test"
        let content = UNMutableNotificationContent()
        content.title = rule?.name ?? "MARC test notification"
        if let rule {
            content.body = "Test alert: " + rule.notificationBody()
        } else {
            content.body = "Notification delivery is working on this iPhone."
        }
        content.interruptionLevel = .active
        if defaults.bool(forKey: "marc.notifications.sound") { content.sound = .default }
        // Reusing one identifier replaces a previous pending test rather than queuing more.
        let request = UNNotificationRequest(identifier: id, content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
        do {
            try await center.add(request)
            // The user may have switched notifications off while the request was being added.
            guard defaults.bool(forKey: "marc.notifications.enabled") else {
                center.removePendingNotificationRequests(withIdentifiers: [id])
                center.removeDeliveredNotifications(withIdentifiers: [id])
                return false
            }
            return true
        } catch {
            failure = "The test could not be scheduled. Check iOS notification settings."
            return false
        }
    }

    @objc private func resetRuleIntervals() {
        deliveryEpoch = UUID()
        ruleEngine.resetIntervals()
        eligibleCustom.removeAll()
    }

    private func persistRuleDeliveries() {
        if let data = try? JSONEncoder().encode(ruleEngine.deliveries) {
            defaults.set(data, forKey: "marc.notifications.deliveries.v1")
        }
    }

    func evaluate(_ snapshot: MacSnapshot, serverID: UUID, sessionID: UUID? = nil) {
        guard Date().timeIntervalSince1970 - snapshot.sampledAt < 30,
              snapshot.sampledAt <= Date().timeIntervalSince1970 + 5 else {
            resetRuleIntervals()
            return
        }
        evaluateCustom(snapshot, serverID: serverID, sessionID: sessionID ?? serverID)
        let batteryThreshold = MARCNotificationThreshold.standardBatteryLimit
        let percentage = true
        let storageThreshold = MARCNotificationThreshold.standardStorageFreePercent
        if let details = snapshot.details, details.hasBattery == true,
           let percent = details.batteryPercent, let source = details.powerSource,
           let condition = MARCNotificationThreshold.battery(percent: percent, source: source, threshold: batteryThreshold) {
            threshold(kind: "battery", serverID: serverID,
                enabled: defaults.bool(forKey: "marc.notifications.battery"),
                low: condition.low, recovered: condition.recovered,
                title: "Mac battery is low",
                body: "Your Mac is at \(Int(percent))% and unplugged.")
        }
        if let condition = MARCNotificationThreshold.storage(
            available: snapshot.diskAvailable, total: snapshot.diskTotal, threshold: storageThreshold, percentage: percentage) {
            threshold(kind: "storage", serverID: serverID,
                enabled: defaults.bool(forKey: "marc.notifications.storage"),
                low: condition.low, recovered: condition.recovered,
                title: "Mac storage is running low",
                body: "Your Mac has \(String(format: "%.1f", snapshot.diskAvailable / snapshot.diskTotal * 100))% storage free.")
        }
    }

    private func evaluateCustom(_ snapshot: MacSnapshot, serverID: UUID, sessionID: UUID) {
        guard defaults.bool(forKey: "marc.notifications.enabled"), authorized else {
            resetRuleIntervals()
            return
        }
        if observedRuleChange != ruleStore.changeID {
            resetRuleIntervals()
            observedRuleChange = ruleStore.changeID
        }
        let previous = ruleEngine.deliveries
        ruleEngine.retain(rules: ruleStore.rules)
        let source = snapshot.details?.powerSource
        let onBattery: Bool? = source == "Battery Power" ? true : (source == "AC Power" ? false : nil)
        let free: Double? = snapshot.diskTotal.isFinite && snapshot.diskTotal > 0 &&
            snapshot.diskAvailable.isFinite && snapshot.diskAvailable >= 0 &&
            snapshot.diskAvailable <= snapshot.diskTotal ? snapshot.diskAvailable / 1_000_000_000 : nil
        let sample = MARCAlertEngine.Sample(cpu: snapshot.cpu,
            memory: snapshot.memoryTotal.isFinite && snapshot.memoryTotal > 0 &&
                snapshot.memoryUsed.isFinite && snapshot.memoryUsed >= 0 &&
                snapshot.memoryUsed <= snapshot.memoryTotal ? snapshot.memoryPercent : nil,
            battery: snapshot.details?.hasBattery == true ? snapshot.details?.batteryPercent : nil,
            storage: free, onBattery: onBattery, storageTotal: snapshot.diskTotal / 1_000_000_000)
        let candidates = Set(ruleEngine.evaluate(rules: ruleStore.rules, sample: sample,
            serverID: serverID, session: sessionID, now: ProcessInfo.processInfo.systemUptime,
            wallTime: Date().timeIntervalSince1970, defaultCooldownMinutes: cooldownMinutes,
            defaultRepeatMinutes: repeatMinutes,
            defaultRecovery: defaults.bool(forKey: "marc.notifications.recovery")))
        eligibleCustom = Set(ruleStore.rules.filter { candidates.contains($0.id) }
            .map { MARCAlertEngine.key($0, serverID: serverID) })
        let recovered = Set(ruleEngine.recoveries)
        eligibleCustom.formUnion(ruleStore.rules.filter { recovered.contains($0.id) }
            .map { MARCAlertEngine.key($0, serverID: serverID) + ".recovery" })
        if previous != ruleEngine.deliveries { persistRuleDeliveries() }
        for rule in ruleStore.rules where recovered.contains(rule.id) {
            let key = MARCAlertEngine.key(rule, serverID: serverID) + ".recovery"
            guard !pending.contains(key) else { continue }
            deliver(id: key, title: rule.name + " recovered", body: "The alert condition no longer applies.",
                serverID: serverID, tab: 0, rule: rule, recovery: true)
        }
        for rule in ruleStore.rules where candidates.contains(rule.id) {
            let key = MARCAlertEngine.key(rule, serverID: serverID)
            guard !pending.contains(key) else { continue }
            deliver(id: key, title: rule.name, body: rule.notificationBody(),
                    serverID: serverID, tab: 0, rule: rule)
        }
    }

    private func threshold(kind: String, serverID: UUID, enabled: Bool,
                           low: Bool, recovered: Bool, title: String, body: String) {
        let key = "marc.notifications.state.\(serverID.uuidString).\(kind)"
        let master = defaults.bool(forKey: "marc.notifications.enabled")
        if recovered {
            if defaults.bool(forKey: key + ".latched"), enabled, master,
               defaults.bool(forKey: "marc.notifications.recovery") {
                defaults.set(true, forKey: key + ".recoveryPending")
            }
            defaults.set(false, forKey: key + ".latched")
        }
        if low { defaults.set(false, forKey: key + ".recoveryPending") }
        if !enabled || !master { defaults.set(false, forKey: key + ".recoveryPending") }
        if enabled, master, recovered, defaults.bool(forKey: key + ".recoveryPending"),
           defaults.bool(forKey: "marc.notifications.recovery"), !pending.contains(key + ".recovery") {
            deliver(id: key + ".recovery", title: kind == "battery" ? "Battery alert cleared" : "Storage alert cleared",
                body: "The alert condition no longer applies.", serverID: serverID, tab: 0,
                stateKey: key, recovery: true)
        }
        let latched = defaults.bool(forKey: key + ".latched")
        let elapsed = Date().timeIntervalSince1970 - defaults.double(forKey: key + ".sent")
        let ready = MARCNotificationThreshold.shouldSend(low: low, latched: latched,
            lastSent: defaults.double(forKey: key + ".sent"), now: Date().timeIntervalSince1970,
            cooldown: Double(cooldownMinutes) * 60) ||
            (low && latched && repeatMinutes > 0 && elapsed >= Double(repeatMinutes) * 60)
        guard enabled, ready, !pending.contains(key) else { return }
        deliver(id: key, title: title, body: body, serverID: serverID, tab: 0, stateKey: key)
    }

    func transferCompleted(serverID: UUID?, upload: Bool) {
        guard let serverID, defaults.bool(forKey: "marc.notifications.transfers"),
              UIApplication.shared.applicationState != .active else { return }
        deliver(id: "marc.transfer.\(UUID().uuidString)", title: "File transfer completed",
                body: upload ? "Your upload finished successfully." : "Your download finished successfully.",
                serverID: serverID, tab: 3)
    }

    private func deliver(id: String, title: String, body: String,
                         serverID: UUID, tab: Int, stateKey: String? = nil, rule: MARCAlertRule? = nil, recovery: Bool = false) {
        guard defaults.bool(forKey: "marc.notifications.enabled") else { return }
        pending.insert(id)
        let epoch = deliveryEpoch
        Task {
            defer { pending.remove(id) }
            await refreshAuthorization()
            guard authorized, defaults.bool(forKey: "marc.notifications.enabled") else { return }
            if let rule {
                guard epoch == deliveryEpoch, ruleStore.rules.contains(where: { $0 == rule && $0.enabled }),
                      observedRuleChange == ruleStore.changeID,
                      eligibleCustom.contains(id) else { return }
            } else {
                let preference = stateKey?.hasSuffix(".battery") == true ? "battery" :
                    (stateKey != nil ? "storage" : "transfers")
                guard defaults.bool(forKey: "marc.notifications." + preference) else { return }
                if recovery {
                    guard let stateKey, defaults.bool(forKey: "marc.notifications.recovery"),
                          defaults.bool(forKey: stateKey + ".recoveryPending") else { return }
                }
            }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.threadIdentifier = "marc.mac.\(serverID.uuidString)"
            content.userInfo = ["serverID": serverID.uuidString, "tab": tab]
            content.interruptionLevel = .active
            if defaults.bool(forKey: "marc.notifications.sound") { content.sound = .default }
            do {
                try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
                if let rule {
                    guard epoch == deliveryEpoch, defaults.bool(forKey: "marc.notifications.enabled"),
                          ruleStore.rules.contains(where: { $0 == rule && $0.enabled }),
                          observedRuleChange == ruleStore.changeID,
                          eligibleCustom.contains(id) else {
                        center.removeDeliveredNotifications(withIdentifiers: [id])
                        return
                    }
                    if recovery { ruleEngine.markRecovered(rule, serverID: serverID) }
                    else { ruleEngine.markSent(rule, serverID: serverID, wallTime: Date().timeIntervalSince1970) }
                    persistRuleDeliveries()
                }
                if let stateKey {
                    if recovery { defaults.set(false, forKey: stateKey + ".recoveryPending") }
                    else {
                        defaults.set(true, forKey: stateKey + ".latched")
                        defaults.set(Date().timeIntervalSince1970, forKey: stateKey + ".sent")
                    }
                }
            } catch {
                failure = "An alert could not be delivered. Check notification settings."
            }
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.identifier == "marc.notifications.test" {
            // Explicit tests show a banner in MARC too; routine alerts keep their quiet behaviour.
            var options: UNNotificationPresentationOptions = [.banner, .list]
            if notification.request.content.sound != nil { options.insert(.sound) }
            completionHandler(options)
        } else {
            // Existing screen feedback stays visible; alerts remain in Notification Center quietly.
            completionHandler([.list])
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
           let value = info["serverID"] as? String, let serverID = UUID(uuidString: value),
           let tab = info["tab"] as? Int, [0, 3].contains(tab) {
            Task { @MainActor in self.destination = Destination(serverID: serverID, tab: tab) }
        }
        completionHandler()
    }
}
