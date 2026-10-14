import SwiftUI
import UIKit

private struct HostTrustSheet: View {
    let request: HostTrustRequest
    let approve: () -> Void
    let cancel: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var matches = false
    @State private var pastedFingerprint = ""
    @State private var copied = false
    @State private var confirmUnverified = false

    private var pastedMatch: Bool {
        HostKeyIdentity.matches(output: pastedFingerprint, fingerprint: request.fingerprint)
    }
    private var hasPasted: Bool { !pastedFingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var canTrust: Bool { hasPasted ? pastedMatch : matches }
    private var command: String {
        switch request.algorithm {
        case "ssh-ed25519": return "ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub -E sha256"
        case "ecdsa-sha2-nistp256", "ecdsa-sha2-nistp384", "ecdsa-sha2-nistp521":
            return "ssh-keygen -lf /etc/ssh/ssh_host_ecdsa_key.pub -E sha256"
        case "ssh-rsa": return "ssh-keygen -lf /etc/ssh/ssh_host_rsa_key.pub -E sha256"
        default: return "for key in /etc/ssh/ssh_host_*_key.pub; do ssh-keygen -lf \"$key\" -E sha256; done"
        }
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Confirm your Mac").font(.system(size: 20, weight: .semibold))
                Text("\(request.host):\(request.port)")
                    .font(.system(size: 13)).textSelection(.enabled)
                Text("Choose how to trust this Mac before your password is sent.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Compare it yourself").font(.system(size: 14, weight: .semibold))
                    Text("Compare this fingerprint with the SSH host fingerprint obtained directly on your Mac.")
                        .font(.system(size: 12)).foregroundStyle(p.muted)
                    Text(request.algorithm).font(.system(size: 11)).foregroundStyle(p.muted)
                    Text(request.fingerprint)
                        .font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                    Toggle("I checked it on my Mac and it matches", isOn: $matches)
                        .font(.system(size: 13)).tint(p.accent).disabled(hasPasted)

                    Divider()
                    DisclosureGroup("Check using a Mac command") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Run this in Terminal on the Mac you want to connect to, then paste the result below.")
                                .font(.system(size: 12)).foregroundStyle(p.muted)
                            Text(command).font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                            Button(copied ? "Copied" : "Copy command") {
                                UIPasteboard.general.string = command
                                copied = true
                            }.font(.system(size: 13)).tint(p.accent).frame(minHeight: 44)
                            TextField("SHA256:… or the full output", text: $pastedFingerprint, axis: .vertical)
                                .font(.system(size: 12, design: .monospaced))
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                                .padding(12).background(p.raised, in: RoundedRectangle(cornerRadius: 10))
                        }.padding(.top, 10)
                    }.font(.system(size: 13)).tint(p.accent)

                    if hasPasted {
                        Text(pastedMatch ? "Fingerprint matches" : "Fingerprint does not match. Check the Mac and pasted result before continuing.")
                            .font(.system(size: 12))
                            .foregroundStyle(pastedMatch ? p.accent : Color.red)
                    }
                }.padding(16).background(p.surface, in: RoundedRectangle(cornerRadius: 16))

                Button(action: approve) {
                    Text("Verify & connect").font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(p.accent.opacity(canTrust ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }.disabled(!canTrust)

                if !canTrust {
                    Button("Trust & connect without checking") { confirmUnverified = true }
                        .font(.system(size: 13)).tint(p.accent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(hasPasted && !pastedMatch)
                }
                Text("MARC remembers this fingerprint in Keychain and blocks unexpected key changes.")
                    .font(.system(size: 12)).foregroundStyle(p.muted)
                Button("Cancel", role: .cancel, action: cancel)
                    .frame(maxWidth: .infinity, minHeight: 44).tint(p.accent)
            }.padding(24)
        }
        .marcCanvas().interactiveDismissDisabled()
        .alert("Trust without verifying?", isPresented: $confirmUnverified) {
            Button("Cancel", role: .cancel) { }
            Button("Trust & connect") {
                guard !hasPasted || pastedMatch else { return }
                approve()
            }
        } message: {
            Text("You have not checked this Mac’s identity. A device impersonating your Mac could receive your login credentials. Continue only if you accept this risk. MARC will remember this key and block future changes.")
        }
    }
}

private struct HostTrustPresentation: ViewModifier {
    let trust: MARCHostTrust
    func body(content: Content) -> some View {
        content.sheet(isPresented: Binding(
            get: { trust.request != nil },
            set: { if !$0 { trust.cancel() } }
        )) {
            if let request = trust.request {
                HostTrustSheet(request: request, approve: trust.approve, cancel: trust.cancel)
            }
        }
    }
}

extension View {
    func hostTrustPrompt(_ trust: MARCHostTrust) -> some View {
        modifier(HostTrustPresentation(trust: trust))
    }
}
