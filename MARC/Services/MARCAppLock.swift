import SwiftUI
import LocalAuthentication
import Observation

@MainActor @Observable
final class MARCAppLock {
    private(set) var enabled = UserDefaults.standard.bool(forKey: "marc.requireAuthentication")
    private(set) var unlocked = false
    private(set) var busy = false
    var failure: String?
    @ObservationIgnored private var context: LAContext?
    @ObservationIgnored private var generation = UUID()

    var authenticationName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "iPhone authentication"
        }
    }

    func background() {
        generation = UUID()
        context?.invalidate()
        context = nil
        busy = false
        unlocked = false
        failure = nil
    }

    private func authenticate(reason: String) async -> Bool {
        guard !busy else { return false }
        let token = UUID()
        generation = token
        let session = LAContext()
        session.localizedCancelTitle = "Cancel"
        session.touchIDAuthenticationAllowableReuseDuration = 0
        var error: NSError?
        guard session.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            failure = error?.localizedDescription ?? "Set an iPhone passcode to use app lock."
            return false
        }
        context = session
        busy = true
        failure = nil
        defer {
            if generation == token { busy = false; context = nil }
        }
        do {
            let success = try await session.evaluatePolicy(
                .deviceOwnerAuthentication, localizedReason: reason
            )
            guard generation == token, !Task.isCancelled else { return false }
            return success
        } catch {
            guard generation == token else { return false }
            if let error = error as? LAError,
               error.code == .userCancel || error.code == .appCancel || error.code == .systemCancel {
                return false
            }
            failure = error.localizedDescription
            return false
        }
    }

    func unlock() async {
        guard enabled, !unlocked else { return }
        if await authenticate(reason: "Unlock your saved Mac connections.") {
            unlocked = true
        }
    }

    func setEnabled(_ value: Bool) async {
        guard value != enabled else { return }
        if await authenticate(reason: value ? "Enable app lock." : "Disable app lock.") {
            enabled = value
            unlocked = true
            UserDefaults.standard.set(value, forKey: "marc.requireAuthentication")
        }
    }
}

struct MARCLockedRoot: View {
    @State private var lock = MARCAppLock()
    @State private var needsUnlock = true
    @Environment(\.scenePhase) private var phase
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.appearance") private var appearance = "system"

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        Group {
            if !lock.enabled || lock.unlocked {
                ContentView()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32)).foregroundStyle(p.accent)
                    Text("MARC is locked")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Unlock with \(lock.authenticationName) or your iPhone passcode.")
                        .font(.system(size: 13)).foregroundStyle(p.muted)
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await lock.unlock() }
                    } label: {
                        HStack {
                            if lock.busy { ProgressView().tint(.white) }
                            Text(lock.busy ? "Authenticating…" : "Unlock MARC")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(p.accent, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                    }.disabled(lock.busy)
                    if let failure = lock.failure {
                        Text(failure).font(.system(size: 12)).foregroundStyle(.red)
                    }
                }
                .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
                .marcCanvas()
            }
        }
        .environment(lock)
        .preferredColorScheme(
            appearance == "system" ? nil : (appearance == "dark" ? .dark : .light)
        )
        .onChange(of: phase) { _, phase in
            if phase == .background {
                lock.background()
                needsUnlock = true
            } else if phase == .active && needsUnlock {
                needsUnlock = false
                Task { await lock.unlock() }
            }
        }
        .onAppear {
            if phase == .active && needsUnlock {
                needsUnlock = false
                Task { await lock.unlock() }
            }
        }
    }
}

struct MARCAppLockSetting: View {
    @Environment(MARCAppLock.self) private var lock
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Require \(lock.authenticationName)", isOn: Binding(
                get: { lock.enabled },
                set: { value in Task { await lock.setEnabled(value) } }
            ))
            .font(.system(size: 15)).tint(p.accent).disabled(lock.busy)
            if lock.busy { ProgressView().controlSize(.small) }
            if let failure = lock.failure {
                Text(failure).font(.system(size: 11)).foregroundStyle(.red)
            }
        }.padding(16)
    }
}
