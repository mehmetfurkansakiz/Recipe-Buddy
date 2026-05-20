import SwiftUI
import UIKit

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentView: AppView = .splash
    @Published var selectedTheme: ThemeOption = ThemePreferencesViewModel().selected
    let dataManager: DataManager
    
    enum AppView {
        case splash
        case onboarding
        case auth
        case ageGate
        case main
    }
    
    var rootView: AnyView {
        switch currentView {
        case .splash:
            return AnyView(
                SplashView(coordinator: self)
                    .preferredColorScheme(selectedTheme.colorScheme)
            )
        case .onboarding:
            return AnyView(
                OnboardingView {
                    Task { await self.completeOnboarding() }
                }
                .preferredColorScheme(selectedTheme.colorScheme)
            )
        case .auth:
            return AnyView(
                AuthenticationView(onAuthSuccess: {
                    self.requestRouteEvaluation()
                })
                .preferredColorScheme(selectedTheme.colorScheme)
            )
        case .ageGate:
            return AnyView(
                AgeGateView(coordinator: self)
                    .preferredColorScheme(selectedTheme.colorScheme)
            )
        case .main:
            return AnyView(
                MainTabView(coordinator: self)
                    .preferredColorScheme(selectedTheme.colorScheme)
            )
        }
    }
    
    private let onboardingCompletedKey = "onboarding_completed_v1"
    private let minimumSplashDuration: TimeInterval = 4.0
    private let splashStartDate = Date()
    private var authStateListenerTask: Task<Void, Never>?
    private var isRouteEvaluationRunning = false
    private var pendingRouteEvaluation = false
    private var isPasswordRecoveryFlowActive = false

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
        
        observeAPNsTokenUpdates()
        observePasswordRecoveryFlowState()
        listenForAuthStateChanges()
        requestRouteEvaluation()
    }

    deinit {
        authStateListenerTask?.cancel()
    }
    
    private func listenForAuthStateChanges() {
        authStateListenerTask = Task { [weak self] in
            guard let self else { return }
            for await state in supabase.auth.authStateChanges {
                if state.event == .signedIn, state.session != nil {
                    if self.isPasswordRecoveryFlowActive {
                        print("ℹ️ signedIn event ignored during password recovery flow.")
                        continue
                    }
                    print("✅ E-posta onayı veya giriş algılandı, route yeniden değerlendiriliyor...")
                    await MainActor.run {
                        self.requestRouteEvaluation()
                    }
                }
            }
        }
    }

    private func requestRouteEvaluation() {
        pendingRouteEvaluation = true
        guard !isRouteEvaluationRunning else { return }

        isRouteEvaluationRunning = true
        Task { @MainActor in
            defer { self.isRouteEvaluationRunning = false }

            while self.pendingRouteEvaluation {
                self.pendingRouteEvaluation = false
                await self.evaluateRouteState()
            }
        }
    }
    
    func retryRouteEvaluation() {
        requestRouteEvaluation()
    }
    
    private func ensureMinimumSplashDuration() async {
        let elapsed = Date().timeIntervalSince(splashStartDate)
        let remaining = minimumSplashDuration - elapsed
        guard remaining > 0 else { return }
        
        let nanoseconds = UInt64(remaining * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    private func evaluateRouteState() async {
        if currentView == .splash {
            await ensureMinimumSplashDuration()
        }
        
        if !UserDefaults.standard.bool(forKey: onboardingCompletedKey) {
            currentView = .onboarding
            return
        }

        do {
            let session = try await supabase.auth.session
            if !session.isExpired {
                await setupMainFlow()
            } else {
                showAuthenticationView()
            }
        } catch {
            // User is not authenticated, show authentication view
            print("❌ Kullanıcı giriş yapmamış, kimlik doğrulama ekranına yönlendiriliyor.")
            showAuthenticationView()
        }
    }

    func completeOnboarding() async {
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        requestRouteEvaluation()
    }
    
    private func setupMainFlow() async {
        print("✅ Veriler yükleniyor...")
        await dataManager.loadInitialUserData()
        await DeviceTokenService.shared.syncStoredTokenIfPossible()

        if dataManager.currentUser?.birthDate == nil {
            print("ℹ️ Yaş bilgisi eksik, age gate gösteriliyor.")
            currentView = .ageGate
            return
        }

        await dataManager.loadHomePageData()
        TelemetryManager.configureFromConsent()
        print("✅ Veriler yüklendi, ana ekrana yönlendiriliyor.")
        currentView = .main
    }

    private func observeAPNsTokenUpdates() {
        NotificationCenter.default.addObserver(
            forName: .apnsDeviceTokenUpdated,
            object: nil,
            queue: .main
        ) { notification in
            guard let token = notification.object as? String, !token.isEmpty else { return }
            Task { @MainActor in
                try? await DeviceTokenService.shared.upsertCurrentDeviceToken(token: token)
            }
        }
    }

    private func observePasswordRecoveryFlowState() {
        NotificationCenter.default.addObserver(
            forName: .passwordRecoveryFlowStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, let isActive = notification.object as? Bool else { return }
            Task { @MainActor in
                self.isPasswordRecoveryFlowActive = isActive
            }
        }
    }

    func completeAgeGate(withBirthDate birthDate: Date) async {
        do {
            let updatedUser = try await UserService.shared.setBirthDate(birthDate)
            dataManager.currentUser = updatedUser
            await dataManager.loadHomePageData()
            TelemetryManager.configureFromConsent()
            currentView = .main
        } catch {
            print("❌ Yaş bilgisi kaydedilemedi: \(error)")
        }
    }

    // Backward compatibility for callers still passing age directly.
    func completeAgeGate(withAge age: Int) async {
        let normalizedAge = max(13, min(age, 120))
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.year = (components.year ?? 2000) - normalizedAge
        components.hour = 12
        components.minute = 0
        components.second = 0
        let birthDate = Calendar.current.date(from: components) ?? Date()
        await completeAgeGate(withBirthDate: birthDate)
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
