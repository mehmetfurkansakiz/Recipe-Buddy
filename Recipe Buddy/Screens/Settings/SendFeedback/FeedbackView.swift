import SwiftUI

struct FeedbackView: View {
    @ObservedObject var viewModel: FeedbackViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showMailComposer = false
    @State private var hasSentFeedback = false

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    introCard
                    typeSection
                    messageSection
                    sendSection
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Geri Bildirim Gönder")
        .inlineColoredNavigationBar(titleColor: .AppPrimary)
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                subject: viewModel.subject,
                body: viewModel.composedBody,
                toRecipients: [viewModel.supportEmail]
            ) { result in
                if result == .sent {
                    hasSentFeedback = true
                    dismiss()
                }
            }
        }
        .tint(.AppPrimary)
    }

    // MARK: - Sections

    private var introCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title2)
                .foregroundStyle(.AppPrimary)
                .padding(.top, 2)

            Text("Görüş ve önerilerin bizim için değerli. Hata bildir, öneride bulun veya genel geri bildirim gönder.")
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

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GERİ BİLDİRİM TÜRÜ")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            Picker("Tür", selection: $viewModel.selectedType) {
                ForEach(FeedbackType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MESAJIN")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            TextEditor(text: $viewModel.message)
                .frame(minHeight: 160)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
                .overlay(alignment: .topLeading) {
                    if viewModel.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Mesajını buraya yaz...")
                            .foregroundStyle(.TextSecondary)
                            .padding(.top, 20)
                            .padding(.leading, 20)
                    }
                }
        }
    }

    private var sendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: sendFeedback) {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("Gönder")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(hasSentFeedback)

            Text("Gönder butonuna bastığında cihazındaki Mail uygulaması açılır. Mail uygulaması kurulu değilse, varsayılan e-posta uygulamasında yeni bir taslak oluşturulur.")
                .font(.footnote)
                .foregroundStyle(.TextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Actions

    private func sendFeedback() {
        guard !hasSentFeedback else { return }
        let trimmed = viewModel.message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if MailComposerView.canSendMail() {
            showMailComposer = true
        } else if let url = viewModel.mailtoURL() {
            hasSentFeedback = true
            UIApplication.shared.open(url)
            dismiss()
        }
    }
}

#Preview {
    NavigationStack { FeedbackView(viewModel: FeedbackViewModel()) }
}
