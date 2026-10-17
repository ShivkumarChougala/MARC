import Foundation
import SwiftUI
import UIKit
import CoreTransferable
import PhotosUI
import QuickLook
import UniformTypeIdentifiers

struct FilesScreen: View {
    let monitor: SSHMonitor
    let files: MARCRemoteFiles
    var onShowTerminal: (String) -> Void = { _ in }
    var onClose: (() -> Void)? = nil
    @State private var selectedEntry: MARCRemoteEntry?
    @State private var actionSheetVisible = false
    @State private var pendingDownload: MARCLocalDownload?
    @State private var search = ""
    @State private var showHidden = false
    @State private var importing = false
    @State private var choosingPhoto = false
    @State private var photoSelection: PhotosPickerItem?
    @State private var preparingPhoto = false
    @State private var photoPreparationID = UUID()
    @State private var photoDestination: MARCFileDestination?
    @State private var importDestination: MARCFileDestination?
    @State private var export: MARCLocalDownload?
    @State private var preview: MARCLocalDownload?
    @State private var showTransferProgress = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"
    @Environment(\.scenePhase) private var scenePhase

    private var connectionID: String {
        "\(monitor.server?.id.uuidString ?? "")-\(monitor.connected)"
    }

    private var visibleEntries: [MARCRemoteEntry] {
        files.entries.filter {
            (showHidden || !$0.name.hasPrefix(".")) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)

        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Group {
                    if let onClose {
                        Button(action: onClose) {
                            Label("Back", systemImage: "chevron.left")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(p.accent)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Return to previous screen")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("Files")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(p.muted)
                    .lineLimit(1)
                    .layoutPriority(1)
                Menu {
                    Button {
                        importDestination = files.captureDestination()
                        importing = importDestination != nil
                    } label: {
                        Label("Files", systemImage: "folder")
                    }
                    Button {
                        photoSelection = nil
                        photoDestination = files.captureDestination()
                        choosingPhoto = photoDestination != nil
                    } label: {
                        Label("Photos & Videos", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 40, height: 40)
                }
                .disabled(!files.ready || files.busy || preparingPhoto)
                .accessibilityLabel("Choose upload source")
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(minHeight: 44)
            .foregroundStyle(p.accent)

            if preparingPhoto || files.transferring {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.mini).tint(p.accent)
                    Text(preparingPhoto ? "Preparing media…" :
                         (files.cancellingTransfer ? "Cancelling…" : files.transferPhase))
                        .font(.system(size: 11))
                        .foregroundStyle(p.muted)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }

            HStack(spacing: 10) {
                Button {
                    files.browse((files.path as NSString).deletingLastPathComponent)
                    search = ""
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 36)
                }
                .disabled(!files.ready || files.busy || files.path == "/")
                .accessibilityLabel("Parent folder")

                ScrollView(.horizontal) {
                    Text(files.path.isEmpty ? "Connecting…" : files.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(p.muted)
                        .textSelection(.enabled)
                }
                .scrollIndicators(.hidden)

                Button {
                    files.browse(files.home)
                    search = ""
                } label: {
                    Image(systemName: "house")
                        .frame(width: 32, height: 36)
                }
                .disabled(!files.ready || files.busy)
                .accessibilityLabel("Home folder")
            }
            .foregroundStyle(p.accent)
            .padding(.horizontal, 8)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(p.muted)
                TextField("Search this folder", text: $search)
                    .font(.system(size: 13))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button { showHidden.toggle() } label: {
                    Image(systemName: showHidden ? "eye" : "eye.slash")
                        .foregroundStyle(showHidden ? p.accent : p.muted)
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Toggle hidden files")
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .background(p.surface, in: RoundedRectangle(cornerRadius: 12))


            // Feedback participates in layout below Search, so navigation
            // can never cover its progress or Cancel control.
            if ((preparingPhoto || files.transferring) && showTransferProgress) || files.completionTitle != nil {
                Group {
                    if preparingPhoto && showTransferProgress {
                        MARCFileTransferCard(
                            title: "Preparing media", filename: "Photo or video",
                            symbol: "photo", detail: "Loading selected item…",
                            progress: nil, cancel: nil
                        )
                    } else if files.transferring && showTransferProgress {
                        MARCFileTransferCard(
                            title: files.cancellingTransfer ? "Cancelling…" : files.transferPhase,
                            filename: files.transferName,
                            symbol: files.previewTransfer ? "eye" : (files.uploadingTransfer ? "arrow.up" : "arrow.down"),
                            detail: transferDetail,
                            progress: files.transferTotal == nil || files.progress >= 1 ? nil : files.progress,
                            cancel: files.cancellingTransfer ? nil : { files.cancelTransfer() }
                        )
                    } else if let title = files.completionTitle {
                        MARCFileCompletionCard(
                            title: title,
                            filename: (files.completionPath as NSString).lastPathComponent
                        )
                        .allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            if let notice = files.notice, !files.busy, !preparingPhoto, !files.transferring, files.completionTitle == nil {
                Text(notice)
                    .font(.system(size: 12)).multilineTextAlignment(.center)
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
            }

            ScrollViewReader { scroll in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(visibleEntries) { entry in
                        HStack(spacing: 0) {
                            Button {
                                if entry.directory { open(entry) }
                                else { actionSheetVisible = true; selectedEntry = entry }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: entry.symbol)
                                        .font(.system(size: 21))
                                        .foregroundStyle(entry.directory ? p.accent : p.muted)
                                        .frame(width: 42, height: 44)
                                        .background(p.accent.opacity(entry.directory ? 0.13 : 0.04),
                                                    in: RoundedRectangle(cornerRadius: 12))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(entry.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(p.text).lineLimit(2)
                                        Text(detail(entry))
                                            .font(.system(size: 10)).foregroundStyle(p.muted)
                                        Text(MARCFileFormatting.permissions(entry.mode))
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(p.muted)
                                    }
                                    Spacer(minLength: 4)
                                }
                                .padding(.leading, 14).padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(entry.directory ? "Open folder" : "Details and actions")
                            Button { actionSheetVisible = true; selectedEntry = entry } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(p.muted)
                                    .frame(width: 48, height: 60)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Details and actions for \(entry.name)")
                        }
                        .background(entry.path == files.lastUploadedPath ? p.accent.opacity(0.12) : p.surface)
                        .disabled(files.busy || !files.ready)
                        .contextMenu {
                            Button("Details and actions") { actionSheetVisible = true; selectedEntry = entry }
                            Button("Copy path") { UIPasteboard.general.string = entry.path }
                        }
                        .id(entry.id)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if !files.busy && visibleEntries.isEmpty {
                    Text(files.ready
                         ? (search.isEmpty ? "This folder is empty." : "No matching files.")
                         : (monitor.connected ? "Files connection unavailable." : "Connect a Mac in Settings."))
                        .font(.system(size: 12))
                        .foregroundStyle(p.muted)
                        .padding(30)
                }
            }
            .contentMargins(.bottom, 16, for: .scrollContent)
            // Keep rows inside the list's allocated viewport above navigation.
            .clipped()
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: files.lastUploadedPath) { _, uploaded in
                guard let uploaded else { return }
                search = ""
                if (uploaded as NSString).lastPathComponent.hasPrefix(".") {
                    showHidden = true
                }
                Task { @MainActor in
                    await Task.yield()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scroll.scrollTo(uploaded, anchor: .top)
                    }
                }
            }
            }

        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: showTransferProgress)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: files.completionTitle)

        .marcCanvas()
        .marcDelayedActivity(
            active: files.busy && !files.transferring && !preparingPhoto && selectedEntry == nil,
            title: files.ready ? files.activity : "Connecting to Files"
        )
        .task(id: preparingPhoto || files.transferring) {
            showTransferProgress = false
            guard preparingPhoto || files.transferring else { return }
            do {
                try await Task.sleep(for: .milliseconds(350))
                try Task.checkCancellation()
                showTransferProgress = true
            } catch {}
        }
        .task(id: files.completionEvent) {
            guard files.completionTitle != nil else { return }
            do {
                try await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    files.completionTitle = nil
                }
            } catch {}
        }

        .task(id: files.notice) {
            guard let notice = files.notice else { return }
            do {
                try await Task.sleep(for: .seconds(2))
                if files.notice == notice { files.notice = nil }
            } catch {}
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: connectionID) { _, _ in
            selectedEntry = nil
            pendingDownload = nil
            importing = false
            choosingPhoto = false
            photoSelection = nil
            photoPreparationID = UUID()
            preparingPhoto = false
        }
        .task(id: connectionID) {
            guard scenePhase != .background, monitor.connected,
                  let server = monitor.server else { return }
            await files.prepare(server: server)
        }
        .photosPicker(
            isPresented: $choosingPhoto,
            selection: $photoSelection,
            matching: .any(of: [.images, .videos]),
            preferredItemEncoding: .current
        )
        .task(id: photoSelection) {
            guard !Task.isCancelled, let item = photoSelection,
                  let destination = photoDestination else { return }
            let preparation = UUID()
            photoPreparationID = preparation
            let folder = destination.path
            preparingPhoto = true
            var imported: URL?

            defer { if photoPreparationID == preparation { preparingPhoto = false } }

            do {
                guard let media = try await item.loadTransferable(
                    type: MARCPhotoImport.self
                ) else {
                    throw MARCAIError.message(
                        "Could not prepare this photo or video."
                    )
                }
                imported = media.url
                try Task.checkCancellation()

                guard scenePhase != .background,
                      files.matchesDestination(destination),
                      files.ready, !files.busy else {
                    throw MARCAIError.message(
                        "The destination changed. Select the item again."
                    )
                }

                let destinationPath = folder == "/"
                    ? "/" + media.url.lastPathComponent
                    : folder + "/" + media.url.lastPathComponent

                guard !files.entries.contains(where: {
                    $0.path == destinationPath
                }) else {
                    throw MARCAIError.message(
                        "A file with this name already exists in this folder."
                    )
                }

                files.upload(media.url, to: destination)
                imported = nil
            } catch {
                if let imported {
                    try? FileManager.default.removeItem(
                        at: imported.deletingLastPathComponent()
                    )
                }
                if !Task.isCancelled, photoPreparationID == preparation,
                   files.matchesDestination(destination) {
                    files.failure = error.localizedDescription
                }
            }
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.item]
        ) { result in
            switch result {
            case .success(let url):
                guard let importDestination else { return }
                files.upload(url, to: importDestination)
            case .failure(let error):
                if let importDestination, files.matchesDestination(importDestination) {
                    files.failure = error.localizedDescription
                }
            }
        }
        .onAppear { receiveDownloadedFile() }
        .onDisappear {
            pendingDownload = nil
            if files.transferring && files.previewTransfer { files.cancelTransfer() }
        }
        .onChange(of: files.downloaded?.id) { _, _ in
            receiveDownloadedFile()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { presentDownloadedFile() }
        }
        .alert("Files", isPresented: Binding(
            get: { files.failure != nil },
            set: { if !$0 { files.failure = nil } }
        )) {
            Button("OK", role: .cancel) { files.failure = nil }
        } message: { Text(files.failure ?? "") }
        .sheet(item: $selectedEntry, onDismiss: {
            actionSheetVisible = false
            presentDownloadedFile()
        }) { entry in
            MARCFileActionSheet(
                entry: entry, files: files,
                open: { selectedEntry = nil; open(entry) },
                download: {
                    selectedEntry = nil
                    if entry.directory { files.downloadFolder(entry) }
                    else { files.download(entry) }
                },
                terminal: {
                    selectedEntry = nil
                    let path = entry.directory ? entry.path : (entry.path as NSString).deletingLastPathComponent
                    onShowTerminal(path)
                }
            )
        }
        .sheet(item: $preview, onDismiss: presentDownloadedFile) { item in
            MARCRemoteFilePreview(file: item)
        }
        .sheet(item: $export, onDismiss: presentDownloadedFile) { item in
            MARCFilesShareSheet(file: item)
        }
    }

    private var transferDetail: String {
        func bytes(_ count: UInt64) -> String {
            ByteCountFormatter.string(fromByteCount: Int64(clamping: count), countStyle: .file)
        }
        guard let total = files.transferTotal else {
            return files.transferPhase == "Preparing folder"
                ? "Packaging folder contents…" : "Connecting to your Mac…"
        }
        return "\(bytes(files.transferBytes)) of \(bytes(total))"
    }

    private func open(_ entry: MARCRemoteEntry) {
        if entry.directory {
            search = ""
            files.browse(entry.path)
        } else {
            files.download(entry, forPreview: true)
        }
    }

    private func receiveDownloadedFile() {
        guard let file = files.downloaded else { return }
        // Transfer ownership out of the connection model before presenting.
        pendingDownload = file
        files.downloaded = nil
        presentDownloadedFile()
    }

    private func presentDownloadedFile() {
        guard scenePhase == .active, !actionSheetVisible,
              selectedEntry == nil, preview == nil, export == nil,
              let file = pendingDownload else { return }
        pendingDownload = nil
        if file.forPreview { preview = file }
        else { export = file }
    }

    private func detail(_ entry: MARCRemoteEntry) -> String {
        let size = entry.directory ? "Folder" : entry.size.map {
            ByteCountFormatter.string(
                fromByteCount: Int64(clamping: $0), countStyle: .file
            )
        } ?? "File"
        guard let modified = entry.modified else { return size }
        return size + " · " + modified.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct MARCFilesShareSheet: UIViewControllerRepresentable {
    let file: MARCLocalDownload

    func makeCoordinator() -> Coordinator { Coordinator(file: file) }

    final class Coordinator {
        let file: MARCLocalDownload
        init(file: MARCLocalDownload) { self.file = file }
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [context.coordinator.file.url], applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ controller: UIActivityViewController, context: Context
    ) {}
}

private struct MARCPhotoImport: Transferable, Sendable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .data) { received in
            let folder = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "MARCPhotoImport-\(UUID().uuidString)",
                    isDirectory: true
                )
            try FileManager.default.createDirectory(
                at: folder, withIntermediateDirectories: true
            )

            do {
                let name = received.file.lastPathComponent
                guard !name.isEmpty, name != ".", name != ".." else {
                    throw MARCAIError.message("Invalid media filename.")
                }
                let destination = folder.appendingPathComponent(name)
                try FileManager.default.copyItem(
                    at: received.file, to: destination
                )
                return MARCPhotoImport(url: destination)
            } catch {
                try? FileManager.default.removeItem(at: folder)
                throw error
            }
        }
    }
}


// One compact transfer surface: progress ring, file identity, status and cancel.
// The ring advances only from bytes already transferred; no decorative looping.
private struct MARCFileTransferCard: View {
    let title: String
    let filename: String
    let symbol: String
    let detail: String
    let progress: Double?
    let cancel: (() -> Void)?

    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        let value = min(1, max(0, progress ?? 0))

        HStack(spacing: 12) {
            ZStack {
                Circle().fill(p.accent.opacity(0.06))
                Circle().stroke(p.accent.opacity(0.12), lineWidth: 2.5)
                if progress != nil {
                    Circle()
                        .trim(from: 0, to: CGFloat(value))
                        .stroke(p.accent.gradient, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .modifier(MARCLiveValueMotion(value: value))
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(p.accent)
                } else {
                    ProgressView().controlSize(.small).tint(p.accent)
                }
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(p.accent)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if progress != nil {
                        MARCLiveNumberText(text: "\(Int(value * 100))%", value: value * 100)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(p.text)
                    }
                }
                Text(filename)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(p.text)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(detail)
                    .font(.system(size: 10))
                    .monospacedDigit()
                    .foregroundStyle(p.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            if let cancel {
                Button(action: cancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(p.muted)
                        .frame(width: 28, height: 28)
                        .background(p.raised, in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel \(title.lowercased())")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, cancel == nil ? 16 : 6)
        .padding(.vertical, 14)
        .background(p.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(colors: [p.accent.opacity(0.22), p.border],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
        }
        .marcLiveReadings(enabled: progress != nil)
    }
}

private struct MARCFileCompletionCard: View {
    let title: String
    let filename: String
    @Environment(\.colorScheme) private var scheme
    @AppStorage("marc.accent") private var marcAccentPreference = "coral"

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(p.accent)
                .frame(width: 44, height: 44)
                .background(p.accent.opacity(0.08), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(p.accent)
                Text(filename)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(p.text)
                    .lineLimit(1).truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(p.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(p.border, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}


private struct MARCRemoteFilePreview: UIViewControllerRepresentable {
    let file: MARCLocalDownload

    func makeCoordinator() -> Coordinator {
        Coordinator(file: file)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let preview = QLPreviewController()
        preview.dataSource = context.coordinator

        let navigation = UINavigationController(rootViewController: preview)
        preview.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.close)
        )
        context.coordinator.navigation = navigation
        return navigation
    }

    func updateUIViewController(
        _ controller: UINavigationController, context: Context
    ) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let file: MARCLocalDownload
        weak var navigation: UINavigationController?

        init(file: MARCLocalDownload) {
            self.file = file
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(
            _ controller: QLPreviewController,
            previewItemAt index: Int
        ) -> QLPreviewItem {
            file.url as NSURL
        }

        @objc func close() {
            navigation?.dismiss(animated: true)
        }
    }
}
