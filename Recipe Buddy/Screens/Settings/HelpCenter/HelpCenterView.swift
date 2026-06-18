import SwiftUI

struct HelpCenterView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var viewModel: HelpCenterViewModel

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    HelpInfoCard()

                    faqSection

                    contactSection

                    resourcesSection

                    appInfoSection
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Yardım Merkezi")
        .inlineColoredNavigationBar(titleColor: .AppPrimary)
    }

    // MARK: - Sections

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SIKÇA SORULAN SORULAR")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.faqItems.enumerated()), id: \.offset) { index, item in
                    DisclosureGroup {
                        Text(item.answer)
                            .font(.subheadline)
                            .foregroundStyle(.TextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.AppPrimary)
                            Text(item.question)
                                .font(.headline)
                                .foregroundStyle(.TextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if index < viewModel.faqItems.count - 1 {
                        Divider().padding(.leading, 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESTEK")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                Button {
                    openSupportEmail(subject: "Destek Talebi")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope")
                        Text("Destek ile İletişime Geç")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .helpButtonContent()
                }
                .buttonStyle(.plain)

                NavigationLink(destination: FeedbackView(viewModel: FeedbackViewModel())) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("Geri Bildirim Gönder")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .helpButtonContent()
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KAYNAKLAR")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                LinkRow(title: "Gizlilik Politikası", systemImage: "hand.raised.fill", url: viewModel.privacyPolicyURL)
                Divider().padding(.leading, 0)
                LinkRow(title: "Kullanım Koşulları", systemImage: "doc.text.fill", url: viewModel.termsURL)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UYGULAMA BİLGİSİ")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.AppPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.appName)
                        .font(.headline)
                        .foregroundStyle(.TextPrimary)
                    Text("Sürüm: \(viewModel.appVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.TextSecondary)
                }
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private func openSupportEmail(subject: String) {
        if let url = viewModel.mailtoURL(subject: subject) {
            openURL(url)
        }
    }
}

// MARK: - Subviews

private struct HelpInfoCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.AppPrimary)
                .padding(.top, 2)

            Text("Yardım Merkezi'nde sıkça sorulan sorulara ulaşabilir, sorunlarını bildirebilir ve bize geri bildirim gönderebilirsin.")
                .font(.body)
                .foregroundStyle(.TextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
    }
}

private struct LinkRow: View {
    let title: String
    let systemImage: String
    let url: URL

    init(title: String, systemImage: String, url: URL) {
        self.title = title
        self.systemImage = systemImage
        self.url = url
    }

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(.AppPrimary)
                Text(LocalizedStringKey(title))
                    .foregroundStyle(.TextPrimary)
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

private extension View {
    func helpButtonContent() -> some View {
        self
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        HelpCenterView(viewModel: HelpCenterViewModel())
    }
}
