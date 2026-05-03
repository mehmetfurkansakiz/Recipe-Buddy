import SwiftUI

struct DataConsentPreferencesView: View {
    @ObservedObject var viewModel: DataConsentPreferencesViewModel
    
    var body: some View {
        ZStack {
            Color.Background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Info Card
                    ConsentInfoCard()
                    
                    // Grouped Toggles + Control Row
                    VStack(spacing: 0) {
                        ConsentToggleRow(
                            isOn: $viewModel.analyticsConsent,
                            icon: "chart.bar.fill",
                            title: "Analitik",
                            subtitle: "Kullanım istatistikleri ile uygulamayı geliştirmemize yardımcı ol",
                            onChange: { _ in viewModel.savePreferences() }
                        )
                        
                        Divider().padding(.leading, 56)
                        
                        ConsentToggleRow(
                            isOn: $viewModel.crashReportsConsent,
                            icon: "exclamationmark.triangle.fill",
                            title: "Çökme Raporları",
                            subtitle: "Hataları tespit etmek için anonim çökme verileri",
                            onChange: { _ in viewModel.savePreferences() }
                        )
                        
                        Divider().padding(.leading, 56)
                        
                        ConsentToggleRow(
                            isOn: $viewModel.personalizationConsent,
                            icon: "person.crop.circle.fill",
                            title: "Kişiselleştirme",
                            subtitle: "İçerik ve önerileri sana göre uyarlayalım",
                            onChange: { _ in viewModel.savePreferences() }
                        )
                        
                        Divider().padding(.leading, 56)
                        
                        ConsentToggleRow(
                            isOn: $viewModel.marketingConsent,
                            icon: "megaphone.fill",
                            title: "Pazarlama",
                            subtitle: "Kampanyalar ve tekliflerle ilgili bildirimler",
                            onChange: { newValue in viewModel.handleMarketingConsentChanged(newValue) }
                        )
                        
                        Divider().padding(.leading, 56)
                        
                        // Control Buttons Row
                        HStack {
                            Spacer()
                            Button(action: { viewModel.acceptAll() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Tümünü Kabul Et")
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(.plain)
                            .tint(.AppPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
                    .padding(.horizontal, 16)
                    
                    // Last Updated Footnote
                    if let text = viewModel.formattedLastUpdated {
                        Text(text)
                            .font(.footnote)
                            .foregroundStyle(.TextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 20)
            }
            
            if viewModel.isLoading || viewModel.isSaving {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView(viewModel.isLoading ? "Yükleniyor..." : "Kaydediliyor...")
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(12)
            }
        }
        .navigationTitle("Veri İzni")
        .inlineColoredNavigationBar(titleColor: .AppPrimary)
    }
}

private struct ConsentToggleRow: View {
    @Binding var isOn: Bool
    let icon: String
    let title: String
    let subtitle: String
    var onChange: ((Bool) -> Void)? = nil

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.AppPrimary)
                    .frame(width: 28, height: 28)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.TextPrimary)
                        .font(.headline)
                    Text(subtitle)
                        .foregroundColor(.TextSecondary)
                        .font(.subheadline)
                        .lineLimit(nil)
                }
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onChange(of: $isOn.wrappedValue) { _, newValue in
            onChange?(newValue)
        }
        .toggleStyle(SwitchToggleStyle(tint: .AppPrimary))
    }
}

private struct ConsentInfoCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundColor(.AppPrimary)
                .padding(.top, 2)

            Text("Veri izinleriniz, uygulamayı kullanım şeklinize göre özelleştirilir ve gizliliğiniz korunur. Tercihlerinizi dilediğiniz zaman değiştirebilirsiniz.")
                .foregroundColor(.TextPrimary)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.SurfaceBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        DataConsentPreferencesView(viewModel: DataConsentPreferencesViewModel())
    }
}
