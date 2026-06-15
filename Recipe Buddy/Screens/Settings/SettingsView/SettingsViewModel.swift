import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var showPremiumAlert = false
    @Published var isSigningOut = false
    
    private let coordinator: AppCoordinator
    
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }
    
    /// Signs the user out.
    func signOut(dataManager: DataManager) async {
        isSigningOut = true
        
        try? await Task.sleep(for: .seconds(1))
        
        do {
            try await supabase.auth.signOut()
            await coordinator.showGuestMainView()
        } catch {
            print("❌ Error signing out from profile: \(error.localizedDescription)")
            isSigningOut = false
        }
    }
}
