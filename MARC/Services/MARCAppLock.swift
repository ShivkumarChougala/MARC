import SwiftUI
import LocalAuthentication
import Observation
import UIKit

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
    // Session state survives removal of the protected UI while authentication is required.
    @State private var store = ServerStore()
    @State private var terminalWorkspace = MARCTerminalWorkspace()
    @State private var tab = 0
    @State private var lock = MARCAppLock()
    @State private var needsUnlock = true
    @Environment(\.scenePhase) private var phase
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.appearance") private var appearance = "system"

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        Group {
            if !lock.enabled || lock.unlocked {
                ContentView(store: store, terminalWorkspace: terminalWorkspace, tab: $tab)
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
        .background(MARCPrivacyShield(lock: lock, phase: phase,
            enabled: lock.enabled, unlocked: lock.unlocked, busy: lock.busy))
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

// A separate, non-key window covers presented sheets as well as the root view.
// UIKit's scene notification is synchronous, before the switcher snapshot;
// waiting for SwiftUI's background render is too late for that snapshot.
private struct MARCPrivacyShield: UIViewRepresentable {
    let lock: MARCAppLock
    let phase: ScenePhase
    let enabled: Bool
    let unlocked: Bool
    let busy: Bool

    func makeCoordinator() -> Coordinator { Coordinator(lock: lock) }
    func makeUIView(context: Context) -> Anchor {
        let view = Anchor()
        view.isUserInteractionEnabled = false
        view.attached = { [weak coordinator = context.coordinator] window in
            coordinator?.attach(window?.windowScene)
        }
        return view
    }
    func updateUIView(_ view: Anchor, context: Context) {
        context.coordinator.attach(view.window?.windowScene)
        context.coordinator.reconcile()
    }
    static func dismantleUIView(_ view: Anchor, coordinator: Coordinator) {
        view.attached = nil
        coordinator.stop()
    }

    final class Anchor: UIView {
        var attached: ((UIWindow?) -> Void)?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            attached?(window)
        }
    }

    @MainActor final class Coordinator: NSObject {
        let lock: MARCAppLock
        private weak var scene: UIWindowScene?
        private var curtain: UIWindow?
        private var unlockButton: UIButton?
        private var failureLabel: UILabel?

        init(lock: MARCAppLock) {
            self.lock = lock
            super.init()
            let center = NotificationCenter.default
            center.addObserver(self, selector: #selector(deactivate(_:)),
                               name: UIScene.willDeactivateNotification, object: nil)
            center.addObserver(self, selector: #selector(background(_:)),
                               name: UIScene.didEnterBackgroundNotification, object: nil)
            center.addObserver(self, selector: #selector(activate(_:)),
                               name: UIScene.didActivateNotification, object: nil)
        }

        func attach(_ value: UIWindowScene?) {
            guard let value else { return }
            if scene !== value {
                curtain?.isHidden = true
                curtain = nil
                scene = value
            }
            reconcile()
        }

        @objc private func deactivate(_ note: Notification) {
            guard let source = note.object as? UIWindowScene, source === scene, lock.enabled else { return }
            show()
            unlockButton?.isHidden = true
        }
        @objc private func background(_ note: Notification) {
            guard let source = note.object as? UIWindowScene, source === scene else { return }
            // Invalidate authentication synchronously, including a late Face ID
            // reply. The SwiftUI phase handler still owns reconnect scheduling.
            lock.background()
            if lock.enabled { show() }
        }
        @objc private func activate(_ note: Notification) {
            guard let source = note.object as? UIWindowScene, source === scene else { return }
            reconcile()
        }

        func reconcile() {
            guard let scene else { return }
            if lock.enabled && (!lock.unlocked || scene.activationState != .foregroundActive) {
                show()
                unlockButton?.isHidden = scene.activationState != .foregroundActive
                unlockButton?.isEnabled = !lock.busy
                failureLabel?.text = lock.failure
            } else {
                curtain?.isHidden = true
            }
        }

        private func show() {
            guard let scene else { return }
            if curtain == nil {
                let window = UIWindow(windowScene: scene)
                window.windowLevel = .alert + 1
                let controller = UIViewController()
                controller.view.backgroundColor = .black
                controller.view.accessibilityViewIsModal = true
                let symbol = UIImageView(image: UIImage(systemName: "lock.fill"))
                symbol.tintColor = .white
                symbol.contentMode = .scaleAspectFit
                symbol.heightAnchor.constraint(equalToConstant: 32).isActive = true
                let title = UILabel()
                title.text = "MARC is locked"
                title.textColor = .white
                title.font = .preferredFont(forTextStyle: .title2)
                title.adjustsFontForContentSizeCategory = true
                title.textAlignment = .center
                title.numberOfLines = 0
                let button = UIButton(type: .system)
                button.setTitle("Unlock MARC", for: .normal)
                button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
                button.titleLabel?.adjustsFontForContentSizeCategory = true
                button.tintColor = .white
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true
                button.addTarget(self, action: #selector(unlock), for: .touchUpInside)
                unlockButton = button
                let failure = UILabel()
                failure.textColor = .white
                failure.font = .preferredFont(forTextStyle: .footnote)
                failure.adjustsFontForContentSizeCategory = true
                failure.textAlignment = .center
                failure.numberOfLines = 0
                failureLabel = failure
                let stack = UIStackView(arrangedSubviews: [symbol, title, button, failure])
                stack.axis = .vertical
                stack.spacing = 20
                stack.translatesAutoresizingMaskIntoConstraints = false
                controller.view.addSubview(stack)
                NSLayoutConstraint.activate([
                    stack.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
                    stack.leadingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.leadingAnchor, constant: 28),
                    stack.trailingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.trailingAnchor, constant: -28)
                ])
                window.rootViewController = controller
                curtain = window
            }
            // Never steal key-window ownership from the app or authentication UI.
            curtain?.isHidden = false
        }

        @objc private func unlock() {
            Task { [weak self] in
                guard let self else { return }
                await lock.unlock()
                reconcile()
            }
        }

        func stop() {
            NotificationCenter.default.removeObserver(self)
            curtain?.isHidden = true
            curtain = nil
            unlockButton = nil
            failureLabel = nil
            scene = nil
        }
        deinit { NotificationCenter.default.removeObserver(self) }
    }
}

struct MARCAppLockSetting: View {
    @Environment(MARCAppLock.self) private var lock
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        let authentication = lock.authenticationName
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { lock.enabled },
                set: { value in Task { await lock.setEnabled(value) } }
            )) {
                HStack(spacing: 12) {
                    MARCSettingsRowIcon(symbol: authentication == "Face ID" ? "faceid" : authentication == "Touch ID" ? "touchid" : "lock")
                    Text("Require \(authentication)")
                }
            }
            .font(.system(size: 15)).disabled(lock.busy)
            if lock.busy { ProgressView().controlSize(.small) }
            if let failure = lock.failure {
                Text(failure).font(.system(size: 11)).foregroundStyle(.red)
            }
        }.padding(.horizontal, 14).padding(.vertical, 10)
            .frame(minHeight: 50)
    }
}
