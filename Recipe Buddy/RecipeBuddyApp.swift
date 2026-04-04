import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct RecipeBuddyApp: App {
    @StateObject private var coordinator = AppCoordinator()
    init() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("ℹ️ FirebaseApp configured at app launch.")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            coordinator.rootView
                .environmentObject(coordinator.dataManager)
                .hideKeyboardOnTap()
                .onOpenURL { url in
                    print("➡️ onOpenURL tetiklendi: \(url)")
                    if url.scheme == "com.mehmetfurkansakiz.Recipe-Buddy" && url.host == "auth-callback" {
                        print("⏳ Auth callback URL alındı, Supabase durumunu kontrol etmesi tetikleniyor...")
                        Task {
                            do {
                                _ = try await supabase.auth.refreshSession()
                                print("✅ Oturum yenileme denemesi yapıldı. AuthState listener'ın durumu yakalaması bekleniyor.")
                            } catch {
                                print("ℹ️ Oturum yenilenirken bilgi (veya hata): \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("⚠️ Bilinmeyen URL alındı: \(url)")
                    }
                }
        }
    }
}

