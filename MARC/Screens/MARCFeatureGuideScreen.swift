import SwiftUI
import UIKit

/// Choose a topic here; the guidance itself appears on the real screen.
struct MARCFeatureGuideScreen: View {
    let connected: Bool
    let show: (MARCFeatureAction) -> Void
    let setup: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("marc.accent") private var accent = MARCAccentColor.defaultColor.rawValue
    @AppStorage("marc.learn.revision") private var hintRevision = 0
    @State private var selected = MARCFeatureAction.moveFile
    @State private var replayedAll = false

    var body: some View {
        let p = MARCPalette(dark: scheme == .dark)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Mac. A little closer.").font(.title2.weight(.semibold))
                        Text("Pick something you’d like to try. We’ll show you where, right on your screen.")
                            .font(.subheadline).foregroundStyle(p.muted)
                    }
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(MARCFeatureAction.allCases) { action in
                                Button {
                                    guard selected != action else { return }
                                    selected = action
                                    UISelectionFeedbackGenerator().selectionChanged()
                                } label: {
                                    Text(action.title).font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 15).frame(minHeight: 44)
                                        .foregroundStyle(selected == action ? p.accent : p.muted)
                                        .background(selected == action ? p.accent.opacity(0.12) : p.surface, in: Capsule())
                                        .overlay(Capsule().stroke(selected == action ? p.accent.opacity(0.5) : p.border, lineWidth: 0.5))
                                }.buttonStyle(.plain)
                                    .accessibilityAddTraits(selected == action ? .isSelected : [])
                            }
                        }.padding(.vertical, 2)
                    }.scrollIndicators(.visible)
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 10) {
                            Image(systemName: selected.symbol).font(.system(size: 20)).foregroundStyle(p.muted)
                            Text(selected.outcome).font(.title3.weight(.semibold))
                        }
                        Text(selected.detail).font(.subheadline).foregroundStyle(p.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("A HINT YOU’LL SEE").font(.caption2.weight(.medium)).tracking(1).foregroundStyle(p.muted)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(selected.hints[0].title).font(.subheadline.weight(.semibold))
                                Text(selected.hints[0].message).font(.footnote).foregroundStyle(p.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(p.accent.opacity(0.5), lineWidth: 1))
                        }
                        Button {
                            replay(selected.hints)
                            show(selected)
                        } label: {
                            HStack {
                                Text("Show me in \(selected.title)")
                                Spacer(minLength: 8)
                                Image(systemName: "arrow.right")
                            }.font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                        }.buttonStyle(.borderedProminent).disabled(!connected)
                        Button("Open directly") {
                            show(selected)
                        }.font(.footnote).frame(minHeight: 44).disabled(!connected)
                            .accessibilityLabel("Open \(selected.title) without replaying dismissed hints")
                    }
                    .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(p.surface.opacity(0.65), in: RoundedRectangle(cornerRadius: 22))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selected)
                    if !connected {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connect your Mac to try it.").font(.subheadline).foregroundStyle(p.muted)
                            Button("Getting started", action: setup).frame(minHeight: 44)
                        }
                    }
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Go at your own pace").font(.subheadline.weight(.medium))
                            Text("Hints appear one at a time. Got it keeps each one dismissed.")
                                .font(.footnote).foregroundStyle(p.muted)
                        }
                        Spacer(minLength: 0)
                        Button(replayedAll ? "Ready" : "Replay all") {
                            replay(MARCLearningHint.allCases)
                            replayedAll = true
                            UISelectionFeedbackGenerator().selectionChanged()
                        }.font(.footnote.weight(.medium)).frame(minWidth: 60, minHeight: 44)
                            .accessibilityLabel("Replay all learning hints")
                    }
                    if replayedAll {
                        Text("All hints are ready. Open a topic above whenever you like.")
                            .font(.footnote).foregroundStyle(p.muted)
                    }
                }.frame(maxWidth: 560).padding(20).frame(maxWidth: .infinity)
            }
            .marcCanvas().foregroundStyle(p.text).tint(p.accent)
            .navigationTitle("What’s inside MARC").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
                .marcToolbarBackgroundHidden()
            }
        }
    }

    private func replay(_ hints: [MARCLearningHint]) {
        for hint in hints { UserDefaults.standard.removeObject(forKey: hint.preferenceKey) }
        hintRevision += 1
    }
}

private extension MARCFeatureAction {
    var title: String {
        switch self {
        case .checkMac: return "Status"
        case .inspectSystem: return "System"
        case .findProcess: return "Processes"
        case .moveFile: return "Files"
        case .controlMac: return "Controls"
        case .runCommand: return "Terminal & AI"
        }
    }
    var symbol: String {
        switch self {
        case .checkMac: return "gauge.with.needle"
        case .inspectSystem: return "desktopcomputer"
        case .findProcess: return "list.bullet.rectangle"
        case .moveFile: return "folder"
        case .controlMac: return "slider.horizontal.3"
        case .runCommand: return "terminal"
        }
    }
    var outcome: String {
        switch self {
        case .checkMac: return "Know how your Mac is doing"
        case .inspectSystem: return "Make sense of the numbers"
        case .findProcess: return "Find the busy app"
        case .moveFile: return "Bring a file over"
        case .controlMac: return "Keep your Mac within reach"
        case .runCommand: return "Get things done at the prompt"
        }
    }
    var detail: String {
        switch self {
        case .checkMac: return "See live usage, spot what needs attention and open your statistics history."
        case .inspectSystem: return "Get a closer look at CPU, memory, network, storage and battery details where available."
        case .findProcess: return "Sort by CPU or memory, find an app, then review its identity before deciding to end it."
        case .moveFile: return "Send a photo to your Mac, download a document, or find your way through folders."
        case .controlMac: return "Use supported volume and brightness controls, manage playback and choose Quick Launch apps."
        case .runCommand: return "Use an SSH shell or ask Local/API AI for a suggestion. You choose what runs."
        }
    }
    var hints: [MARCLearningHint] {
        switch self {
        case .checkMac: return [.statusSystem, .status]
        case .inspectSystem: return [.systemCPU, .systemMemory, .systemStorage]
        case .findProcess: return [.processes]
        case .moveFile: return [.files, .filesFolders, .filesActions]
        case .controlMac: return [.controls]
        case .runCommand: return [.terminal]
        }
    }
}
