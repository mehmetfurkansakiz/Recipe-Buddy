import SwiftUI

struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    accountActionsSection
                    deleteAccountSection
                    Spacer(minLength: 72)
                }
                .padding()
            }
            .allowsHitTesting(!viewModel.isSigningOut)
            .navigationTitle("Gelişmiş Ayarlar")
            .inlineColoredNavigationBar(titleColor: .AppPrimary)

            if viewModel.isSigningOut {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Çıkış Yapılıyor...")
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .transition(.opacity)
            }
        }
    }

    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HESAP İŞLEMLERİ")
                .font(.caption)
                .foregroundStyle(.TextSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button {
                    navigationPath.append(AppNavigation.changePassword)
                } label: {
                    SettingsRowView(title: "Parolayı Değiştir", icon: "key.fill", iconColor: .AppPrimary)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading)

                Button {
                    Task { await viewModel.signOut(dataManager: dataManager) }
                } label: {
                    SettingsRowView(title: "Çıkış Yap", icon: "rectangle.portrait.and.arrow.right", iconColor: .red)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }

    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KALICI İŞLEM")
                .font(.caption)
                .foregroundStyle(.TextSecondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 12) {
                Text("Hesabını kalıcı olarak silmek istiyorsan aşağıdaki ekrana geçebilirsin.")
                    .font(.footnote)
                    .foregroundStyle(.TextSecondary)

                Button {
                    navigationPath.append(AppNavigation.deleteAccount)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text("Hesabı Sil")
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
                    .foregroundStyle(.red)
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
}

#Preview {
    NavigationStack {
        AdvancedSettingsView(
            viewModel: SettingsViewModel(coordinator: AppCoordinator()),
            navigationPath: .constant(NavigationPath())
        )
        .environmentObject(DataManager())
    }
}
