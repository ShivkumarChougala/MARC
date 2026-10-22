import SwiftUI

enum MARCLegalPage: Equatable {
    case privacy, terms

    var title: String { self == .privacy ? "Privacy Policy" : "Terms of Use" }
    var resource: String { self == .privacy ? "MARCPrivacyPolicy" : "MARCTermsOfUse" }
    var publishedURL: URL {
        URL(string: self == .privacy ? "https://getmarc.app/privacy" : "https://getmarc.app/terms")!
    }
}

private struct MARCLegalDocument: Decodable {
    struct Section: Decodable, Identifiable {
        struct Reference: Decodable {
            let title: String
            let url: URL
        }
        let id: String
        let title: String
        let paragraphs: [String]
        let links: [Reference]
    }
    let title: String
    let effectiveDate: String
    let introduction: String
    let contactEmail: String
    let sections: [Section]

    static func load(_ page: MARCLegalPage) -> Self? {
        guard let url = Bundle.main.url(forResource: page.resource, withExtension: "json")
                ?? Bundle.main.url(forResource: page.resource, withExtension: "json", subdirectory: "Resources"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

private struct MARCLegalSummaryRow: Identifiable {
    let icon: String
    let title: String
    let detail: String
    var id: String { title }
}

private extension MARCLegalPage {
    var introduction: String {
        switch self {
        case .privacy:
            return "How MARC handles your information, where it stays, and the choices you have."
        case .terms:
            return "Using MARC responsibly, with clear expectations for access, commands, and third-party services."
        }
    }

    var summary: [MARCLegalSummaryRow] {
        switch self {
        case .privacy:
            return [
                .init(icon: "laptopcomputer", title: "Direct SSH connection",
                      detail: "Your connection goes directly to the Mac you choose."),
                .init(icon: "person.crop.circle", title: "No MARC account or advertising",
                      detail: "The app has no MARC account, advertising or cross-app tracking."),
                .init(icon: "sparkles", title: "AI sharing is optional",
                      detail: "API requests go to the provider you choose, after your approval.")
            ]
        case .terms:
            return [
                .init(icon: "laptopcomputer", title: "Only access authorized Macs",
                      detail: "Connect to devices and accounts you own or have permission to manage."),
                .init(icon: "terminal", title: "Commands affect real files",
                      detail: "Actions can change files, processes and settings on your Mac."),
                .init(icon: "doc.text", title: "Review AI commands before Run",
                      detail: "Run sends the command and Return to your active terminal.")
            ]
        }
    }
}

struct MARCLegalScreen: View {
    private let page: MARCLegalPage
    private let document: MARCLegalDocument?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(_ page: MARCLegalPage) {
        self.page = page
        document = MARCLegalDocument.load(page)
    }

    private var palette: MARCPalette { MARCPalette(dark: scheme == .dark) }
    private var accent: Color { MARCAccentColor.coral.color(dark: scheme == .dark) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let document {
                        heading(document).id("legal-top")
                        summary.padding(.top, 26)
                        sectionMenu(document, proxy: proxy).padding(.top, 8)
                        Text(verbatim: document.introduction)
                            .font(.body).lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                            .padding(.top, 24)
                        ForEach(Array(document.sections.enumerated()), id: \.element.id) { item in
                            policySection(item.element, number: item.offset + 1)
                                .padding(.top, 28)
                                .id(item.element.id)
                        }
                        footer(document, proxy: proxy).padding(.top, 32)
                    } else {
                        Text(page.title).font(.largeTitle.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Text("The bundled document could not be loaded. You can open the published version below.")
                            .padding(.top, 16)
                        publishedLink.padding(.top, 24)
                    }
                }
                .foregroundStyle(palette.text)
                .frame(maxWidth: 640, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
            .background(palette.background)
        }
        .tint(accent)
        .navigationTitle("Legal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func heading(_ document: MARCLegalDocument) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: document.title)
                .font(.largeTitle.weight(.semibold)).tracking(-0.7)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text("Effective \(document.effectiveDate)")
                .font(.subheadline).foregroundStyle(palette.muted)
            Text(verbatim: page.introduction)
                .font(.body).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("At a glance")
                .font(.headline).accessibilityAddTraits(.isHeader)
                .padding(.bottom, 6)
            ForEach(Array(page.summary.enumerated()), id: \.element.id) { item in
                if item.offset > 0 {
                    Divider().overlay(palette.border.opacity(0.4)).padding(.leading, 38)
                }
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: item.element.icon)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(palette.muted)
                        .frame(width: 24).padding(.top, 2)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(verbatim: item.element.title).font(.subheadline.weight(.medium))
                        Text(verbatim: item.element.detail)
                            .font(.footnote).foregroundStyle(palette.muted).lineSpacing(2)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 14)
                .accessibilityElement(children: .combine)
            }
            Text("A guide to the full document below.")
                .font(.caption).foregroundStyle(palette.muted).padding(.top, 2)
        }
        .padding(18)
        .background(palette.surface.opacity(scheme == .dark ? 0.55 : 1),
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(palette.border.opacity(0.5), lineWidth: 0.5)
        }
    }

    private func sectionMenu(_ document: MARCLegalDocument, proxy: ScrollViewProxy) -> some View {
        Menu {
            ForEach(Array(document.sections.enumerated()), id: \.element.id) { item in
                Button("\(item.offset + 1). \(item.element.title)") {
                    jump(to: item.element.id, proxy: proxy)
                }
            }
        } label: {
            HStack {
                Text("Jump to section").font(.subheadline)
                Spacer(minLength: 12)
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.muted)
            }
            .foregroundStyle(palette.text)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Jump to section")
        .accessibilityHint("Choose a heading in this document")
        .overlay(alignment: .bottom) { Divider() }
    }

    private func policySection(_ section: MARCLegalDocument.Section, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(String(format: "%02d", number))
                    .font(.subheadline.weight(.medium)).monospacedDigit()
                    .foregroundStyle(accent).accessibilityHidden(true)
                Text(verbatim: section.title)
                    .font(.headline).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { item in
                Text(verbatim: item.element)
                    .font(.body).lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            ForEach(Array(section.links.enumerated()), id: \.offset) { item in
                Link(destination: item.element.url) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(verbatim: item.element.title)
                        Image(systemName: "arrow.up.right").font(.caption)
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline)
                    .frame(minHeight: 44, alignment: .leading)
                }
            }
            Divider().padding(.top, 8)
        }
    }

    private func footer(_ document: MARCLegalDocument, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Link(destination: URL(string: "mailto:\(document.contactEmail)")!) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Questions? Get in touch").foregroundStyle(palette.text)
                    Text(verbatim: document.contactEmail)
                }
                .font(.subheadline).frame(minHeight: 44, alignment: .leading)
            }
            publishedLink
            Text("This document is included with this app version. Website and email links open the service you choose.")
                .font(.footnote).foregroundStyle(palette.muted).lineSpacing(3)
            Button { jump(to: "legal-top", proxy: proxy) } label: {
                Label("Back to top", systemImage: "arrow.up")
                    .font(.subheadline).frame(minHeight: 44)
            }
            .buttonStyle(.plain).foregroundStyle(accent)
        }
    }

    private var publishedLink: some View {
        Link(destination: page.publishedURL) {
            Label("Read on getmarc.app", systemImage: "arrow.up.right")
                .font(.subheadline).frame(minHeight: 44, alignment: .leading)
        }
    }

    private func jump(to id: String, proxy: ScrollViewProxy) {
        if reduceMotion {
            proxy.scrollTo(id, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(id, anchor: .top)
            }
        }
    }
}
