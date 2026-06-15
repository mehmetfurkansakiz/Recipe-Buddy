import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct RecipeBuddyApp: App {
    @UIApplicationDelegateAdaptor(PushNotificationAppDelegate.self) private var appDelegate
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
                .onOpenURL { url in
                    let expectedScheme = "com.mehmetfurkansakiz.Recipe-Buddy"
                    let expectedHost = "auth-callback"

                    guard url.scheme == expectedScheme, url.host == expectedHost else {
                        #if DEBUG
                        print("ℹ️ Ignored non-auth callback URL.")
                        #endif
                        return
                    }

                    #if DEBUG
                    print("⏳ Received auth callback, refreshing Supabase session...")
                    #endif

                    Task {
                        do {
                            _ = try await supabase.auth.refreshSession()
                            #if DEBUG
                            print("✅ Session refresh attempted after auth callback.")
                            #endif
                        } catch {
                            #if DEBUG
                            print("⚠️ Session refresh failed after callback.")
                            #endif
                        }
                    }
                }
                .task {
                    await NotificationPermissionManager.shared.registerForRemoteNotificationsIfAuthorized()
                }
        }
    }
}
