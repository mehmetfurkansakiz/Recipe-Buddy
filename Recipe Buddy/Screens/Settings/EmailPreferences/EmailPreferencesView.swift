import SwiftUI

struct EmailPreferencesView: View {
    @ObservedObject var viewModel: EmailPreferencesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("E-POSTA TERCİHLERİ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.AppPrimary)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("E-posta Bildirimleri Hakkında")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Buradaki tercihler, uygulamamızdan alacağın e-posta bildirimlerinin türünü belirler. Dilediğin zaman bu ayarlara geri dönüp değiştirebilirsin.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))

                    VStack(spacing: 0) {
                        Toggle(isOn: $viewModel.emailNewsletter) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill").foregroundStyle(.AppPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bültenler").fontWeight(.semibold)
                                    Text("Haftalık ipuçları ve öneriler").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .onChange(of: viewModel.emailNewsletter) { oldValue, newValue in
                            viewModel.savePreferences()
                        }

                        Divider().padding(.leading)

                        Toggle(isOn: $viewModel.emailProductUpdates) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles").foregroundStyle(.AppPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ürün Güncellemeleri").fontWeight(.semibold)
                                    Text("Yeni özellikler ve duyurular").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .onChange(of: viewModel.emailProductUpdates) { oldValue, newValue in
                            viewModel.savePreferences()
                        }

                        Divider().padding(.leading)

                        Toggle(isOn: $viewModel.emailRecipeTips) {
                            HStack(spacing: 12) {
                                Image(systemName: "fork.knife").foregroundStyle(.AppPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tarif İpuçları").fontWeight(.semibold)
                                    Text("Özel içerikler ve öneriler").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .onChange(of: viewModel.emailRecipeTips) { oldValue, newValue in
                            viewModel.savePreferences()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))

                    if let error = viewModel.errorMessage {
                        Text(LocalizedStringKey(error))
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("E-posta")
            .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)

            if viewModel.isLoading {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView("Kaydediliyor...")
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(12)
            }
        }
        .tint(.AppPrimary)
    }
}

#Preview {
    NavigationStack {
        EmailPreferencesView(viewModel: EmailPreferencesViewModel())
    }
}
