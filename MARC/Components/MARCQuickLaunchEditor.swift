import SwiftUI
import UIKit

struct MARCQuickLaunchEditor: View {
    let load: () async throws -> [MARCLaunchApplication]
    let save: ([MARCLaunchApplication]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected: [MARCLaunchApplication]
    @State private var applications: [MARCLaunchApplication] = []
    @State private var query = ""
    @State private var loading = true
    @State private var failure: String?
    @State private var retry = 0
    @State private var feedback: String?
    @State private var arranging = false

    init(selected: [MARCLaunchApplication], load: @escaping () async throws -> [MARCLaunchApplication],
         save: @escaping ([MARCLaunchApplication]) -> Void) {
        _selected = State(initialValue: selected)
        self.load = load
        self.save = save
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if selected.isEmpty { Text("Choose apps below.").foregroundStyle(.secondary) }
                    ForEach(selected) { app in
                        HStack {
                            Label { Text(app.title) } icon: { MARCLaunchIcon(app: app, size: 28) }
                            Spacer(minLength: 8)
                            if !arranging {
                                Button(role: .destructive) {
                                    selected.removeAll { $0.id == app.id }
                                    report("Removed \(app.title)")
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3).frame(width: 44, height: 44)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Remove \(app.title) shortcut")
                            }
                        }
                    }
                    .onDelete {
                        selected.remove(atOffsets: $0)
                        report("Shortcut removed")
                    }
                    .onMove {
                        selected.move(fromOffsets: $0, toOffset: $1)
                        report("Order updated")
                    }
                } header: {
                    HStack {
                        Text("Your shortcuts · \(selected.count)")
                        Spacer()
                        Button(arranging ? "Done" : "Reorder") {
                            UISelectionFeedbackGenerator().selectionChanged()
                            arranging.toggle()
                        }
                            .buttonStyle(.borderless)
                            .disabled(selected.count < 2 && !arranging)
                    }.textCase(nil)
                }
                footer: { Text("Tap the red minus to remove a shortcut. Reorder changes the order; Save keeps your changes.") }

                Section("Apps on this Mac") {
                    if loading {
                        HStack { ProgressView(); Text("Reading installed apps…") }
                    } else if let failure {
                        Text(failure).foregroundStyle(.secondary)
                        Button("Try again") { retry += 1 }
                    } else {
                        if arranging {
                            Text("Tap Done above to add more apps.").foregroundStyle(.secondary)
                        }
                        if selected.count >= MARCQuickLaunchSelection.maximumCount {
                            Text("Remove a shortcut before adding another.").foregroundStyle(.secondary)
                        }
                        let selectedIDs = Set(selected.map(\.id))
                        let available = applications.filter { app in
                            !selectedIDs.contains(app.id) &&
                                (query.isEmpty || app.title.localizedCaseInsensitiveContains(query))
                        }
                        if available.isEmpty {
                            Text(query.isEmpty ? "No more apps found." : "No matching apps.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(available) { app in
                            Button {
                                guard selected.count < MARCQuickLaunchSelection.maximumCount else { return }
                                selected.append(app)
                                report("Added \(app.title)")
                            } label: {
                                HStack {
                                    Label { Text(app.title) } icon: { MARCLaunchIcon(app: app, size: 28) }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                }.frame(minHeight: 44)
                            }
                            .disabled(arranging || selected.count >= MARCQuickLaunchSelection.maximumCount)
                            .deleteDisabled(true).moveDisabled(true)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let feedback {
                    Label(feedback + " · Tap Save to keep changes", systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.medium))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16).padding(.bottom, 8)
                }
            }
            .environment(\.editMode, .constant(arranging ? .active : .inactive))
            .searchable(text: $query, prompt: "Find an app")
            .navigationTitle("Quick Launch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        save(selected)
                        dismiss()
                    }
                }
            }
            .task(id: retry) {
                loading = true; failure = nil
                do {
                    let apps = try await load()
                    try Task.checkCancellation()
                    applications = apps
                    selected = selected.map { old in apps.first(where: { $0.id == old.id }) ?? old }
                    loading = false
                } catch is CancellationError {} catch {
                    guard !Task.isCancelled else { return }
                    failure = "Could not read apps from this Mac. Check the connection and try again."
                    loading = false
                }
            }
        }
    }

    private func report(_ message: String) {
        feedback = message
        UISelectionFeedbackGenerator().selectionChanged()
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
