import SwiftUI
import UIKit

private struct MARCConnectionAlert: ViewModifier {
    @Binding var failure: String?

    private var parts: [Substring] {
        (failure ?? "").split(separator: "\n", maxSplits: 1)
    }

    private var title: String {
        parts.count > 1 ? String(parts[0]) : "Connection needs attention"
    }

    private var detail: String {
        parts.count > 1 ? String(parts[1]) : (failure ?? "")
    }

    func body(content: Content) -> some View {
        content.alert(title, isPresented: Binding(
            get: { failure != nil },
            set: { if !$0 { failure = nil } }
        )) {
            Button("OK", role: .cancel) { failure = nil }
        } message: {
            Text(detail)
        }
        .onChange(of: failure) { _, value in
            if value != nil {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        }
    }
}

extension View {
    func marcConnectionAlert(_ failure: Binding<String?>) -> some View {
        modifier(MARCConnectionAlert(failure: failure))
    }
}
