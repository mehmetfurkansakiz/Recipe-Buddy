import SwiftUI
import NukeUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    accountSection
                    notificationsSection
                    appearanceSection
                    dataPrivacySection
                    helpSupportSection
                    aboutSection
                    dangerZoneSection
                    
                    Spacer(minLength: 72)
                }
                .padding()
            }
            .allowsHitTesting(!viewModel.isSigningOut)
            .background(Color.Background)
            .navigationTitle("Ayarlar")
            .inlineColoredNavigationBar(titleColor: .AppPrimary, textStyle: .headline, weight: .bold, hidesOnSwipe: true, transparentBackground: true)
            .alert("Yakında", isPresented: $viewModel.showPremiumAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("Bu özellik yakında sizlerle olacak!")
            }
            
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
    
    /// Section for account-related actions, expanded with edit profile and more.
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HESAP")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                Button(action: { viewModel.showPremiumAlert = true }) {
                    SettingsRowView(title: "Üyeliği Yönet", icon: "crown.fill", iconColor: .AppPrimary)
                }
                
                Divider().padding(.leading)
                
                Button {
                    navigationPath.append(AppNavigation.editProfile)
                } label: {
                    SettingsRowView(title: "Profili Düzenle", icon: "pencil", iconColor: .AppPrimary)
                }
                
                Divider().padding(.leading)
                
                Button {
                    navigationPath.append(AppNavigation.changePassword)
                } label: {
                    SettingsRowView(title: "Parolayı Değiştir", icon: "key.fill", iconColor: .AppPrimary)
                }
                
                Divider().padding(.leading)
                
                Button {
                    navigationPath.append(AppNavigation.emailPreferences)
                } label: {
                    SettingsRowView(title: "E-posta Tercihleri", icon: "envelope.fill", iconColor: .AppPrimary)
                }
            }
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }
    
    /// Section for notification settings.
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BİLDİRİMLER")
                .font(.caption)
                .foregroundStyle(.TextSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                Button {
                    navigationPath.append(AppNavigation.notificationPreferences)
                } label: {
                    SettingsRowView(title: "Bildirimleri Yönet", icon: "bell.fill", iconColor: .AppPrimary)
                }
            }
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }
    
    /// Section for appearance and theme settings.
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GÖRÜNÜM")
                .font(.caption)
                .foregroundStyle(.TextSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                Button {
                    navigationPath.append(AppNavigation.themePreferences)
                } label: {
                    SettingsRowView(title: "Tema", icon: "paintbrush.fill", iconColor: .AppPrimary)
                }
            }
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }
    
    /// Section for data & privacy related settings.
    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VERİ & GİZLİLİK")
                .font(.caption)
                .foregroundStyle(.TextSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                Button {
                    viewModel.showPremiumAlert = true
                } label: {
                    SettingsRowView(title: "Veri İzni", icon: "lock.shield.fill", iconColor: .AppPrimary)
                }
            }
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }
    
    /// Section for help and support related settings.
    private var helpSupportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YARDIM & DESTEK")
                .font(.caption)
                .foregroundStyle(.TextSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                Button {
                    viewModel.showPremiumAlert = true
                } label: {
                    SettingsRowView(title: "Yardım Merkezi", icon: "questionmark.circle.fill", iconColor: .AppPrimary)
                }
                
                Divider().padding(.leading)
                
                Button {
                    viewModel.showPremiumAlert = true
                } label: {
                    SettingsRowView(title: "Geri Bildirim Gönder", icon: "paperplane.fill", iconColor: .AppPrimary)
                }
            }
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }
    
    /// Section for app information like policies and version.
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HAKKINDA")
                .font(.caption)
                .foregroundStyle(.TextSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                Link(destination: URL(string: "https://www.yourapp.com/privacy")!) {
                    SettingsRowView(title: "Gizlilik Politikası", icon: "shield.fill", iconColor: .AppPrimary)
                }
                
                Divider().padding(.leading)
                
                Link(destination: URL(string: "https://www.yourapp.com/terms")!) {
                    SettingsRowView(title: "Kullanım Koşulları", icon: "doc.text.fill", iconColor: .AppPrimary)
                }
                
                Divider().padding(.leading)
                
                SettingsRowView(
                    title: "Versiyon",
                    icon: "info.circle.fill",
                    iconColor: .AppPrimary,
                    version: appVersion()
                )
            }
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }
    
    /// Section with destructive actions pinned at the bottom.
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HESAP İŞLEMLERİ")
                .font(.caption)
                .foregroundStyle(.TextSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                Button {
                    Task { await viewModel.signOut(dataManager: dataManager) }
                } label: {
                    SettingsRowView(title: "Çıkış Yap", icon: "rectangle.portrait.and.arrow.right", iconColor: .red)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                
                Divider().padding(.leading)
                
                Button(role: .destructive) {
                    // TODO: Implement account deletion action
                } label: {
                    SettingsRowView(title: "Hesabı Sil", icon: "trash.fill", iconColor: .red)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .background(.thinMaterial.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
        }
    }
    
    /// A helper function to get the app version.
    private func appVersion() -> String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "Bilinmiyor"
        }
        return "\(version) (\(build))"
    }
}

/// A reusable view for a single row in the settings screen.
struct SettingsRowView: View {
    let title: String
    let icon: String
    let iconColor: Color
    var version: String? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(iconColor)
            
            Text(title)
                .foregroundStyle(.TextPrimary)
            
            Spacer()
            
            if let version {
                Text(version)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.AppPrimary)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            viewModel: SettingsViewModel(coordinator: AppCoordinator()),
            navigationPath: .constant(NavigationPath())
        )
        .environmentObject(DataManager())
    }
}

