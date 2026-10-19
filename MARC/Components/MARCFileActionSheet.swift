import SwiftUI
import UIKit

extension MARCRemoteEntry {
    var symbol: String {
        if directory { return "folder.fill" }
        switch (name as NSString).pathExtension.lowercased() {
        case "zip", "gz", "tar", "7z", "rar": return "doc.zipper"
        case "swift", "py", "js", "ts", "sh", "json", "html", "css": return "chevron.left.forwardslash.chevron.right"
        case "png", "jpg", "jpeg", "heic", "gif", "webp": return "photo"
        case "mp4", "mov", "mkv": return "film"
        case "mp3", "wav", "m4a", "flac": return "music.note"
        default: return "doc"
        }
    }
}

struct MARCActivityCard: View {
    let title: String
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var accent = "coral"

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        VStack(spacing: 16) {
            ProgressView().tint(p.accent)
            Text(title).font(.system(size: 13, weight: .medium))
                .foregroundStyle(p.text).multilineTextAlignment(.center)
        }
        .padding(26)
        .frame(minWidth: 180, maxWidth: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

private enum MARCFilePanel: String, Identifiable {
    case edit, rename, permissions
    var id: String { rawValue }
}

struct MARCFileActionSheet: View {
    let entry: MARCRemoteEntry
    let files: MARCRemoteFiles
    let open: () -> Void
    let download: () -> Void
    let terminal: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var accent = "coral"
    @State private var info: MARCFileInfo?
    @State private var loading = true
    @State private var failure: String?
    @State private var panel: MARCFilePanel?
    @State private var confirmDelete = false
    @State private var copied = false

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: entry.symbol)
                            .font(.system(size: 26))
                            .foregroundStyle(p.accent)
                            .frame(width: 60, height: 60)
                            .background(p.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 18))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(entry.name).font(.system(size: 22, weight: .semibold)).lineLimit(3)
                            Text(info?.symlink == true ? "Symbolic link" : (entry.directory ? "Folder" : "File"))
                                .font(.system(size: 13)).foregroundStyle(p.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    VStack(spacing: 0) {
                        metadata("Where", (entry.path as NSString).deletingLastPathComponent, p)
                        metadata(entry.directory ? "Directory entry size" : "Size", sizeText, p)
                        metadata("Modified", dateText(info?.modified, fallback: entry.modified), p)
                        metadata("Last accessed", dateText(info?.accessed), p)
                        metadata("Permissions", info.map { $0.permissions + " · " + $0.octal } ??
                                 MARCFileFormatting.permissions(entry.mode), p)
                        metadata("Owner", info.map { "\($0.owner) · uid \($0.uid)" } ?? "Unavailable", p)
                        metadata("Group", info.map { "\($0.group) · gid \($0.gid)" } ?? "Unavailable", p, divider: false)
                    }
                    .padding(.horizontal, 14)
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 18))
                    VStack(spacing: 0) {
                        if entry.directory {
                            action("Open folder", "folder", palette: p, perform: open)
                        } else {
                            if info?.editorSupported == true {
                                action("View and edit", "doc.text", subtitle: "UTF-8 text files up to 1 MB", palette: p) {
                                    panel = .edit
                                }
                            } else if let reason = info?.editorReason {
                                Text(reason)
                                    .font(.system(size: 11)).foregroundStyle(p.muted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                            }
                            action("Preview", "eye", palette: p, perform: open)
                        }
                        action(entry.directory ? "Download folder" : "Download", "arrow.down",
                               subtitle: entry.directory ? "Download as a .tar.gz archive" : "Save to Files or open in another app",
                               palette: p, perform: download)
                        action("Share or open in…", "square.and.arrow.up",
                               subtitle: entry.directory ? "Share the downloaded archive" : "Download, then choose an app",
                               palette: p, perform: download)
                        action("Rename or move", "pencil", palette: p) { panel = .rename }
                            .disabled(protectedEntry)
                        action("Permissions", "lock", subtitle: info?.octal, palette: p) { panel = .permissions }
                            .disabled(info == nil || info?.symlink == true)
                        action(copied ? "Path copied" : "Copy path", copied ? "checkmark" : "doc.on.doc", palette: p) {
                            UIPasteboard.general.string = entry.path
                            copied = true
                        }
                        action("Show in Terminal", "terminal", subtitle: "Review a cd command at the shell prompt", palette: p,
                               perform: terminal)
                        action("Delete", "trash", subtitle: entry.directory ? "Folder and all its contents" : nil,
                               palette: p, destructive: true) { confirmDelete = true }
                            .disabled(protectedEntry)
                    }
                    .background(p.surface, in: RoundedRectangle(cornerRadius: 18))
                    .disabled(loading || files.busy)
                }
                .padding(18)
            }
            .foregroundStyle(p.text)
            .marcCanvas()
            .navigationTitle("Details and actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.disabled(files.busy)
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .marcDelayedActivity(active: loading || files.busy, title: loading ? "Loading details" : "Updating item")
            .task(id: entry.path) {
                defer { loading = false }
                do { info = try await files.perform("info", entry: entry).info }
                catch is CancellationError {} catch { failure = error.localizedDescription }
            }
            .sheet(item: $panel) { panel in
                switch panel {
                case .edit: MARCRemoteTextEditor(entry: entry, files: files)
                case .rename:
                    MARCRemoteRenameSheet(entry: entry, files: files) { dismiss() }
                case .permissions:
                    if let info {
                        MARCRemotePermissionsSheet(entry: entry, info: info, files: files) { self.info = $0 }
                    }
                }
            }
            .confirmationDialog("Delete \(entry.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task { @MainActor in
                        do {
                            _ = try await files.perform("delete", entry: entry, refresh: true)
                            dismiss()
                        } catch is CancellationError {
                        } catch { failure = error.localizedDescription }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(entry.path + (entry.directory ? "\nThis permanently deletes the folder and its contents." : "\nThis permanently deletes the item."))
            }
            .alert("File action", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("OK", role: .cancel) { failure = nil }
            } message: { Text(failure ?? "") }
        }
        .tint(p.accent)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(files.busy)
    }

    private var protectedEntry: Bool { entry.path == "/" || entry.path == files.home }
    private var sizeText: String {
        guard let bytes = info?.size ?? entry.size else { return "Unavailable" }
        return ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .file) + " · \(bytes) bytes"
    }
    private func dateText(_ seconds: Double?, fallback: Date? = nil) -> String {
        guard let date = seconds.map({ Date(timeIntervalSince1970: $0) }) ?? fallback else { return "Unavailable" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
    private func metadata(_ title: String, _ value: String, _ p: MARCPalette, divider: Bool = true) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(title).foregroundStyle(p.muted).frame(width: 108, alignment: .leading)
                Spacer(minLength: 0)
                Text(value).foregroundStyle(p.text).multilineTextAlignment(.trailing).textSelection(.enabled)
            }
            .font(.system(size: 12)).padding(.vertical, 14)
            if divider { Divider().overlay(p.border) }
        }
    }
    private func action(_ title: String, _ icon: String, subtitle: String? = nil, palette p: MARCPalette,
                        destructive: Bool = false, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 20)).frame(width: 30)
                    .foregroundStyle(destructive ? .red : p.accent)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(destructive ? .red : p.text)
                    if let subtitle { Text(subtitle).font(.system(size: 11)).foregroundStyle(p.muted) }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(p.muted)
            }
            .padding(16).frame(minHeight: 60).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 60) }
    }
}

private struct MARCRemoteTextEditor: View {
    let entry: MARCRemoteEntry
    let files: MARCRemoteFiles
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var original = ""
    @State private var fingerprint: [String]?
    @State private var loading = true
    @State private var saving = false
    @State private var failure: String?
    @State private var discard = false

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .font(.system(size: 13, design: .monospaced))
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .disabled(loading || saving || fingerprint == nil)
                .overlay {
                    if loading {
                        ProgressView("Opening text file…")
                            .padding(18)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(12)
                .navigationTitle(entry.name).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            if text != original { discard = true } else { dismiss() }
                        }.disabled(saving)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") { save() }
                            .disabled(loading || saving || fingerprint == nil || text == original)
                    }
                    .sharedBackgroundVisibility(.hidden)
                }
                .marcDelayedActivity(active: saving, title: "Saving text")
                .task {
                    defer { loading = false }
                    do {
                        let response = try await files.perform("readText", entry: entry)
                        try Task.checkCancellation()
                        guard let content = response.text, let info = response.info else {
                            throw MARCAIError.message("The server did not return this text file.")
                        }
                        text = content; original = content; fingerprint = info.fingerprint
                    } catch is CancellationError {} catch { failure = error.localizedDescription }
                }
                .alert("Text editor", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                    Button("OK", role: .cancel) {
                        failure = nil
                        // A failed open has no document to leave in the editor.
                        // Save errors keep the loaded text available for retry.
                        if fingerprint == nil { dismiss() }
                    }
                } message: { Text(failure ?? "") }
                .confirmationDialog("Discard unsaved edits?", isPresented: $discard, titleVisibility: .visible) {
                    Button("Discard edits", role: .destructive) { dismiss() }
                    Button("Keep editing", role: .cancel) {}
                }
        }
        .interactiveDismissDisabled(saving || text != original)
    }
    private func save() {
        guard let fingerprint, !saving else { return }
        saving = true
        let content = text
        Task { @MainActor in
            defer { saving = false }
            do {
                _ = try await files.perform("saveText", entry: entry,
                    extras: ["data": Data(content.utf8).base64EncodedString(), "fingerprint": fingerprint], refresh: true)
                original = content
                dismiss()
            } catch { failure = error.localizedDescription }
        }
    }
}

private struct MARCRemoteRenameSheet: View {
    let entry: MARCRemoteEntry
    let files: MARCRemoteFiles
    let completed: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var moving = false
    @State private var name = ""
    @State private var destination = ""
    @State private var saving = false
    @State private var failure: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Action", selection: $moving) {
                    Text("Rename").tag(false); Text("Move").tag(true)
                }.pickerStyle(.segmented)
                Section(moving ? "Full destination path" : "New name") {
                    if moving { TextField("/absolute/path/new-name", text: $destination) }
                    else { TextField("Name", text: $name) }
                    Text(moving ? "Include the item’s final name. Existing items are never overwritten." : "Rename this item in its current folder.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .navigationTitle("Rename or move").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(saving) }
                .sharedBackgroundVisibility(.hidden)
            }
            .onAppear { name = entry.name; destination = entry.path }
            .marcDelayedActivity(active: saving, title: "Moving item")
            .alert("Rename or move", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("OK", role: .cancel) { failure = nil }
            } message: { Text(failure ?? "") }
        }
        .interactiveDismissDisabled(saving)
    }
    private func save() {
        guard !saving else { return }
        let target: String
        if moving {
            guard destination.hasPrefix("/"), !destination.contains("\0") else {
                failure = "Enter an absolute destination path, including the final name."; return
            }
            target = destination
        } else {
            guard !name.isEmpty, name != ".", name != "..", !name.contains("/"), !name.contains("\0") else {
                failure = "Enter a name without a slash."; return
            }
            let parent = (entry.path as NSString).deletingLastPathComponent
            target = parent == "/" ? "/" + name : parent + "/" + name
        }
        saving = true
        Task { @MainActor in
            defer { saving = false }
            do {
                _ = try await files.perform("rename", entry: entry, extras: ["destination": target], refresh: true)
                dismiss()
                completed()
            } catch { failure = error.localizedDescription }
        }
    }
}

private struct MARCRemotePermissionsSheet: View {
    let entry: MARCRemoteEntry
    let info: MARCFileInfo
    let files: MARCRemoteFiles
    let completed: (MARCFileInfo) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var mode: UInt32 = 0
    @State private var octal = ""
    @State private var saving = false
    @State private var failure: String?

    var body: some View {
        NavigationStack {
            Form {
                ForEach([6, 3, 0], id: \.self) { shift in
                    Section(shift == 6 ? "Owner" : (shift == 3 ? "Group" : "Others")) {
                        permission("Read", bit: UInt32(4) << shift)
                        permission("Write", bit: UInt32(2) << shift)
                        permission(entry.directory ? "Enter folder / execute" : "Execute", bit: UInt32(1) << shift)
                    }
                }
                Section("Octal mode") {
                    TextField("644", text: $octal).keyboardType(.numberPad)
                        .onChange(of: octal) { _, value in
                            if let parsed = UInt32(value, radix: 8), value.count <= 4 { mode = parsed }
                        }
                    Text(MARCFileFormatting.permissions((info.mode & 0xF000) | mode)).font(.system(.body, design: .monospaced))
                    Text("Applies only to this item. Folder contents are unchanged.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .disabled(saving)
            .navigationTitle("Permissions").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(saving) }
                .sharedBackgroundVisibility(.hidden)
            }
            .onAppear { mode = info.mode & 0o7777; octal = String(mode, radix: 8) }
            .marcDelayedActivity(active: saving, title: "Updating permissions")
            .alert("Permissions", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("OK", role: .cancel) { failure = nil }
            } message: { Text(failure ?? "") }
        }
        .interactiveDismissDisabled(saving)
    }
    private func permission(_ title: String, bit: UInt32) -> some View {
        Toggle(title, isOn: Binding(get: { mode & bit != 0 }, set: { value in
            mode = value ? mode | bit : mode & ~bit
            octal = String(mode, radix: 8)
        }))
    }
    private func save() {
        guard !saving, !octal.isEmpty, octal.count <= 4,
              let parsed = UInt32(octal, radix: 8), parsed <= 0o7777 else {
            failure = "Enter a three- or four-digit octal mode using digits 0–7."; return
        }
        saving = true
        Task { @MainActor in
            defer { saving = false }
            do {
                let response = try await files.perform("permissions", entry: entry, extras: ["mode": Int(parsed)], refresh: true)
                if let info = response.info { completed(info) }
                dismiss()
            } catch { failure = error.localizedDescription }
        }
    }
}

// Quick operations finish without flashing a blocking overlay. The task cancels
// when the operation ends or the view leaves the hierarchy.
private struct MARCDelayedActivity: ViewModifier {
    let active: Bool
    let title: String
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if active && visible {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text(title).font(.system(size: 12, weight: .medium))
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(20)
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .combine)
                }
            }
            .task(id: active) {
                visible = false
                guard active else { return }
                do {
                    try await Task.sleep(for: .milliseconds(300))
                    try Task.checkCancellation()
                    visible = true
                } catch {}
            }
    }
}

extension View {
    func marcDelayedActivity(active: Bool, title: String) -> some View {
        modifier(MARCDelayedActivity(active: active, title: title))
    }
}
