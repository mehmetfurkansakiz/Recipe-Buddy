import SwiftUI

struct NotificationPreferencesView: View {
    @ObservedObject var viewModel: NotificationPreferencesViewModel

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("BİLDİRİMLER")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "bell.circle.fill")
                            .foregroundStyle(.AppPrimary)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bildirimler Hakkında")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Uygulamadan gönderilen anlık bildirimlerin türlerini buradan yönetebilirsin. Sistem izinleri için iOS Ayarları'nı kullanman gerekir.")
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
                        // System level toggle info
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.pushEnabled ? "bell.badge.fill" : "bell.slash.fill")
                                .foregroundStyle(viewModel.pushEnabled ? .green : .red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sistem Bildirim İzni")
                                    .fontWeight(.semibold)
                                Text(LocalizedStringKey(viewModel.pushEnabled ? "Açık" : "Kapalı"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(viewModel.isDenied ? "Ayarlar" : (viewModel.pushEnabled ? "Ayarlar" : "İzin Ver")) {
                                if viewModel.isDenied {
                                    viewModel.openSystemSettings()
                                } else if viewModel.pushEnabled {
                                    viewModel.openSystemSettings()
                                } else {
                                    viewModel.requestAuthorizationIfNeeded(enabling: true)
                                }
                            }
                            .font(.footnote)
                            .tint(.AppPrimary)
                            .buttonStyle(.bordered)
                        }
                        .padding()

                        Divider().padding(.leading)

                        Toggle(isOn: $viewModel.pushComments) {
                            HStack(spacing: 12) {
                                Image(systemName: "text.bubble.fill").foregroundStyle(.AppPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Yorumlar")
                                        .fontWeight(.semibold)
                                    Text("Tariflerine yeni yorum geldiğinde").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .onChange(of: viewModel.pushComments) { _, _ in viewModel.savePreferences() }

                        Divider().padding(.leading)

                        Toggle(isOn: $viewModel.pushFavorites) {
                            HStack(spacing: 12) {
                                Image(systemName: "heart.fill").foregroundStyle(.AppPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Favoriler")
                                        .fontWeight(.semibold)
                                    Text("Tariflerin favorilendiğinde").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .onChange(of: viewModel.pushFavorites) { _, _ in viewModel.savePreferences() }

                        Divider().padding(.leading)

                        Toggle(isOn: $viewModel.pushRecipeUpdates) {
                            HStack(spacing: 12) {
                                Image(systemName: "fork.knife").foregroundStyle(.AppPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tarif Güncellemeleri")
                                        .fontWeight(.semibold)
                                    Text("Takip ettiğin tariflerde önemli değişiklikler").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .onChange(of: viewModel.pushRecipeUpdates) { _, _ in viewModel.savePreferences() }

                        Divider().padding(.leading)

                        Toggle(isOn: $viewModel.pushMarketing) {
                            HStack(spacing: 12) {
                                Image(systemName: "megaphone.fill").foregroundStyle(.AppPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Kampanya ve Duyurular")
                                        .fontWeight(.semibold)
                                    Text("Özel kampanyalar ve fırsatlar").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .onChange(of: viewModel.pushMarketing) { _, _ in viewModel.savePreferences() }
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
            .navigationTitle("Bildirimler")
            .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)

            if viewModel.isLoading || viewModel.isSaving {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView(viewModel.isLoading ? "Yükleniyor..." : "Kaydediliyor...")
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(12)
            }
        }
        .tint(.AppPrimary)
    }
}

#Preview {
    NavigationStack { NotificationPreferencesView(viewModel: NotificationPreferencesViewModel()) }
}
