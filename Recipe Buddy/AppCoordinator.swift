import SwiftUI
import UIKit

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentView: AppView = .splash
    @Published var selectedTheme: ThemeOption = ThemePreferencesViewModel().selected
    let dataManager: DataManager
    
    enum AppView {
        case splash
        case auth
        case main
    }
    
    var rootView: AnyView {
        switch currentView {
        case .splash:
            return AnyView(
                SplashView(coordinator: self)
                    .preferredColorScheme(selectedTheme.colorScheme)
            )
        case .auth:
            return AnyView(
                AuthenticationView(onAuthSuccess: {
                    Task { await self.setupMainApp()}
                })
                .preferredColorScheme(selectedTheme.colorScheme)
            )
        case .main:
            return AnyView(
                MainTabView(coordinator: self)
                    .preferredColorScheme(selectedTheme.colorScheme)
            )
        }
    }
    
    init() {
        let dm = DataManager()
        self.dataManager = dm
        
        // Listen for theme changes and update appearance
        NotificationCenter.default.addObserver(forName: .themeChanged, object: nil, queue: .main) { [weak self] notification in
            guard let self = self else { return }
            // Ensure we're on the main actor to update published UI state and appearance
            Task { @MainActor in
                if let option = notification.object as? ThemeOption {
                    self.selectedTheme = option
                    // Re-apply nav bar appearance so dynamic colors are resolved for new scheme
                    AppCoordinator.configureNavigationBarAppearance()
                }
            }
        }
        
        AppCoordinator.configureNavigationBarAppearance()
        
        listenForAuthStateChanges()
        
        Task {
            await checkAuthenticationStatus()
        }
    }
    
    private func listenForAuthStateChanges() {
        Task {
            for await state in supabase.auth.authStateChanges {
                if state.event == .signedIn, state.session != nil {
                    print("✅ E-posta onayı veya giriş algılandı, ana uygulama kuruluyor...")
                    await setupMainApp()
                }
            }
        }
    }
    
    func checkAuthenticationStatus() async {
        try? await Task.sleep(for: .seconds(1))
        
        do {
            let session = try await supabase.auth.session
            if !session.isExpired {
                await setupMainApp()
            } else {
                showAuthenticationView()
            }
        } catch {
            // User is not authenticated, show authentication view
            print("❌ Kullanıcı giriş yapmamış, kimlik doğrulama ekranına yönlendiriliyor.")
            showAuthenticationView()
        }
    }
    
    private func setupMainApp() async {
        print("✅ Veriler yükleniyor...")
        await dataManager.loadInitialUserData()
        await dataManager.loadHomePageData()
        TelemetryManager.configureFromConsent()
        print("✅ Veriler yüklendi, ana ekrana yönlendiriliyor.")
        currentView = .main
    }
    
    func showAuthenticationView() {
        dataManager.clearUserData()
        currentView = .auth
    }
    
    @MainActor
    private static func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.TextPrimary)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.TextPrimary)
        ]
        // Ensure custom back indicator is used during transitions
        if let backImage = UIImage(systemName: "chevron.backward")?.withRenderingMode(.alwaysTemplate) {
            appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        }
        
        UINavigationBar.appearance().tintColor = UIColor(Color.AppPrimary)
        UIBarButtonItem.appearance().tintColor = UIColor(Color.AppPrimary)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

