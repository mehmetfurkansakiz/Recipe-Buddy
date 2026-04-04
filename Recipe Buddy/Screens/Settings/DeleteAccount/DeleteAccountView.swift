import SwiftUI

struct DeleteAccountView: View {
    @ObservedObject var viewModel: DeleteAccountViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    warningCard
                    detailsSection
                    actionsSection
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Hesabı Sil")
        .inlineColoredNavigationBar(titleColor: .AppPrimary)
        .task {
            await viewModel.loadPendingRequest()
        }
        .alert("Hata", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var warningCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.Warning)
                .padding(.top, 2)

            Text("Hesap silme işlemi geri alınamaz. Bu işlem sonrasında profil bilgilerin, tariflerin ve ilişkili verilerin kalıcı olarak silinebilir.")
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

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("İŞLEM ÖNCESİ")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 10) {
                bulletRow("Hesap silme talebin güvenli şekilde hesabın ile eşleştirilerek kaydedilir.")
                bulletRow("Talep sonrası geri dönüş için destek ekibi seninle iletişime geçebilir.")
                bulletRow("Bu işlem hesabındaki oturum bilgileri üzerinden doğrulanır.")
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                Task { await viewModel.submitDeletionRequest() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text(viewModel.hasPendingRequest ? "Talep Alındı" : "Hesap Silme Talebi Oluştur")
                        .fontWeight(.semibold)
                    Spacer()
                    if !viewModel.hasPendingRequest {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSubmitting || viewModel.hasPendingRequest)

            if viewModel.hasPendingRequest {
                Text(viewModel.remainingDaysText)
                    .font(.footnote)
                    .foregroundStyle(.TextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.hasPendingRequest {
                Button("Vazgeç (Talebi İptal Et)") {
                    Task {
                        let cancelled = await viewModel.cancelDeletionRequest()
                        if cancelled {
                            dismiss()
                        }
                    }
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button("Vazgeç") {
                    dismiss()
                }
                .foregroundStyle(.TextSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(.TextSecondary)
                .padding(.top, 6)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.TextPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView(viewModel: DeleteAccountViewModel())
    }
}
