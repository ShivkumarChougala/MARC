import SwiftUI

private struct MARCOpenSourceNotices: Decodable {
    struct Package: Decodable, Identifiable {
        struct Document: Decodable {
            let path: String
            let text: String
        }
        let id: String
        let name: String
        let version: String
        let revision: String
        let repository: String
        let documents: [Document]
    }
    let title: String
    let introduction: String
    let marcLicense: String
    let acknowledgement: String
    let packages: [Package]

    static func load() -> Self? {
        guard let url = Bundle.main.url(forResource: "MARCOpenSourceNotices", withExtension: "json")
                ?? Bundle.main.url(forResource: "MARCOpenSourceNotices", withExtension: "json", subdirectory: "Resources"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

struct MARCOpenSourceScreen: View {
    private let notices = MARCOpenSourceNotices.load()
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = MARCPalette(dark: scheme == .dark)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let notices {
                    Text(verbatim: notices.introduction)
                        .font(.subheadline).foregroundStyle(palette.muted)
                    Text(verbatim: notices.acknowledgement)
                        .font(.footnote).foregroundStyle(palette.muted)
                    NavigationLink {
                        MARCLicenseTextScreen(title: "MARC License", subtitle: "MIT License",
                                              documents: [("LICENSE", notices.marcLicense)])
                    } label: {
                        licenseRow("MARC", detail: "MIT License", palette: palette)
                    }
                    .buttonStyle(.plain)
                    LazyVStack(spacing: 0) {
                        ForEach(notices.packages) { package in
                            NavigationLink {
                                MARCLicenseTextScreen(
                                    title: package.name,
                                    subtitle: "Version \(package.version)\nRevision \(package.revision)\n\(package.repository)",
                                    documents: package.documents.map { ($0.path, $0.text) })
                            } label: {
                                licenseRow(package.name, detail: package.version, palette: palette)
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                } else {
                    Text("Open-source notices could not be loaded. Please reinstall the app or contact MARC support.")
                        .font(.subheadline)
                }
            }
            .padding(20)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(palette.background)
        .foregroundStyle(palette.text)
        .navigationTitle("Open-source licenses")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func licenseRow(_ title: String, detail: String, palette: MARCPalette) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: title).font(.subheadline.weight(.medium))
                Text(verbatim: detail).font(.footnote).foregroundStyle(palette.muted)
            }
            Spacer(minLength: 12)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(palette.muted)
                .accessibilityHidden(true)
        }
        .foregroundStyle(palette.text)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

private struct MARCLicenseTextScreen: View {
    let title: String
    let subtitle: String
    let documents: [(String, String)]
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = MARCPalette(dark: scheme == .dark)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                Text(verbatim: subtitle).font(.footnote).foregroundStyle(palette.muted)
                    .textSelection(.enabled)
                ForEach(documents.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(verbatim: documents[index].0)
                            .font(.subheadline.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Text(verbatim: documents[index].1)
                            .font(.footnote).lineSpacing(3)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Divider()
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(palette.text)
        .background(palette.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
