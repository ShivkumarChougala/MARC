import Foundation
import Network
import NIOCore
import Darwin

struct MARCConnectionIssue {
    enum Kind: Equatable {
        case network, timeout, login, key, identity, keychain, session, compatibility, unknown
    }
    let kind: Kind
    let title: String
    let detail: String

    var message: String { title + "\n" + detail }

    var canRetry: Bool {
        [.network, .timeout, .session, .unknown].contains(kind)
    }

    var symbol: String {
        switch kind {
        case .compatibility: return "desktopcomputer"
        case .identity: return "shield.lefthalf.filled"
        case .key, .keychain: return "key"
        case .login: return "person.crop.circle.badge.exclamationmark"
        default: return "wifi.exclamationmark"
        }
    }

    var actionTitle: String {
        switch kind {
        case .identity: return "Review Mac identity"
        case .key, .keychain: return "Review Keychain"
        case .login: return "Review login"
        default: return "Connection settings"
        }
    }

    static func message(
        _ error: Error, login: MARCCredentials.Saved? = nil
    ) -> String {
        classify(error, login: login).message
    }

    static func classify(
        _ error: Error,
        login: MARCCredentials.Saved? = nil,
        depth: Int = 0
    ) -> Self {
        if let platform = error as? MARCPlatformError {
            return .init(
                kind: .compatibility,
                title: platform == .unsupported ? "This device isn’t supported" : "macOS couldn’t be verified",
                detail: platform.localizedDescription
            )
        }

        if let trust = error as? HostTrustError {
            switch trust {
            case .changed:
                return .init(
                    kind: .identity, title: "Mac identity changed",
                    detail: "Connection blocked. Verify the SSH fingerprint directly on your Mac before changing its saved trust in Keychain. MARC will not automatically trust a changed key."
                )
            case .storage:
                return .init(
                    kind: .keychain, title: "Keychain unavailable",
                    detail: "MARC couldn’t read or save this Mac’s fingerprint. Unlock your iPhone and try again. If it continues, review Settings → Keychain."
                )
            }
        }

        if error is SSHTestError {
            return .init(
                kind: .identity, title: "Mac identity couldn’t be checked",
                detail: "Check the server address and Remote Login. Review this Mac’s fingerprint in Settings → Keychain before reconnecting."
            )
        }

        if let key = error as? MARCLoginError {
            switch key {
            case .missing:
                return .init(
                    kind: .login, title: "Login required",
                    detail: "Enter the Mac username and password, or select a saved SSH key."
                )
            case .invalidKey:
                return .init(
                    kind: .key, title: "SSH key couldn’t be opened",
                    detail: "Check the key’s passphrase and OpenSSH Ed25519 format in Settings → Keychain. An incorrect passphrase or damaged key can cause this."
                )
            }
        }

        if let keychain = error as? MARCKeyStoreError {
            return .init(
                kind: .keychain, title: "Saved key needs attention",
                detail: keychain.localizedDescription
            )
        }

        if error is HostProbeTimeout {
            return .init(
                kind: .timeout, title: "SSH didn’t respond",
                detail: "MARC couldn’t get an SSH response in time. Check the address, network, and Remote Login, then retry."
            )
        }

        if let channel = error as? ChannelError {
            switch channel {
            case .connectTimeout(_):
                return .init(
                    kind: .timeout, title: "Connection timed out",
                    detail: "Wake your Mac, check its current address and Remote Login, and check that your iPhone’s network can reach it. Then retry."
                )
            case .eof:
                return .init(
                    kind: .session, title: "SSH connection closed",
                    detail: "The connection ended before the request finished. Check the Mac and retry."
                )
            default: break
            }
        }

        if let io = error as? IOError,
           let issue = posix(io.errnoCode) {
            return issue
        }

        if let nw = error as? NWError {
            switch nw {
            case .posix(let code):
                if let issue = posix(code.rawValue) { return issue }
            case .dns:
                return .init(
                    kind: .network, title: "Server address couldn’t be resolved",
                    detail: "Check the host name and your network connection. For a nearby Mac, refresh discovery or check its current address."
                )
            default: break
            }
        }

        let ns = error as NSError
        if ns.domain == NSPOSIXErrorDomain,
           let issue = posix(Int32(ns.code)) {
            return issue
        }

        if ns.domain == NSOSStatusErrorDomain {
            return .init(
                kind: .keychain, title: "Login couldn’t be saved",
                detail: "MARC couldn’t save the login securely. Unlock your iPhone and try again. Review the saved login before reconnecting."
            )
        }

        if ns.domain == "MARC", ns.code == 41 {
            return .init(
                kind: .timeout, title: "SSH port didn’t respond",
                detail: "Check the Mac’s address, port, network, and Remote Login, then retry."
            )
        }

        if depth < 3,
           let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error {
            let issue = classify(underlying, login: login, depth: depth + 1)
            if issue.kind != .unknown { return issue }
        }

        // This private Citadel error can also mean that login stalled.
        let typeName = String(reflecting: type(of: error))
        if typeName.hasPrefix("Citadel."),
           typeName.hasSuffix(".AuthenticationFailed") {
            return .init(
                kind: .login, title: "SSH login didn’t complete",
                detail: login?.isKeyLogin == true
                    ? "Check the Mac account’s short username and that the selected key’s public key is authorized for it. Remote Login must allow this account. A stalled SSH login can also cause this."
                    : "Use the Mac account’s short username and Mac login password. Check that Remote Login allows this account. A stalled SSH login can also cause this."
            )
        }

        if typeName.hasSuffix(".NIOConnectionError") {
            return .init(
                kind: .network, title: "Mac couldn’t be reached",
                detail: "Wake your Mac, check its current address and confirm Remote Login is enabled. Check that your iPhone’s network can reach it, then retry."
            )
        }

        return .init(
            kind: .unknown, title: "Connection couldn’t be completed",
            detail: "MARC couldn’t identify the exact cause. Retry once; if it continues, review the server address, login, and SSH settings."
        )
    }

    private static func posix(_ code: Int32) -> Self? {
        switch code {
        case ECONNREFUSED:
            return .init(
                kind: .network, title: "SSH connection refused",
                detail: "On your Mac, check System Settings → General → Sharing → Remote Login. Enable it for your account and check the server port, then retry."
            )
        case ETIMEDOUT:
            return .init(
                kind: .timeout, title: "Connection timed out",
                detail: "Wake your Mac, check its current address and Remote Login, and check that your iPhone’s network can reach it. Then retry."
            )
        case ENETUNREACH, EHOSTUNREACH, ENETDOWN:
            return .init(
                kind: .network, title: "Network unavailable",
                detail: "Check your iPhone’s network and that it can reach this Mac. Then retry."
            )
        case ECONNRESET, EPIPE:
            return .init(
                kind: .session, title: "SSH connection interrupted",
                detail: "The connection was interrupted. Check the Mac’s network and retry."
            )
        case EACCES, EPERM:
            return .init(
                kind: .network, title: "Connection access denied",
                detail: "Check MARC’s Local Network permission in iPhone Settings and the Mac’s network or firewall rules."
            )
        default: return nil
        }
    }
}
