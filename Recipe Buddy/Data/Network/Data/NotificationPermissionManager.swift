import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationPermissionManager {
    static let shared = NotificationPermissionManager()
    private init() {}

    private let defaults = UserDefaults.standard
    private let promptAttemptedKey = "notifications_prompt_attempted_once"

    func hasAttemptedPrompt() -> Bool {
        defaults.bool(forKey: promptAttemptedKey)
    }

    func markPromptAttempted() {
        defaults.set(true, forKey: promptAttemptedKey)
    }

    private func shouldRequestFromSystem(consentManager: ConsentManager) -> Bool {
        guard consentManager.hasUserDecided() else { return false }
        return consentManager.marketingAllowed() || consentManager.personalizationAllowed()
    }

    private func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Requests push permission at most once from app flow and only when user consent allows it.
    func requestIfEligible(consentManager: ConsentManager = .shared) async {
        guard shouldRequestFromSystem(consentManager: consentManager) else { return }
        guard !hasAttemptedPrompt() else { return }

        let status = await authorizationStatus()
        guard status == .notDetermined else {
            if status == .authorized || status == .provisional || status == .ephemeral {
                registerForRemoteNotifications()
            }
            markPromptAttempted()
            return
        }

        markPromptAttempted()
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if granted {
            registerForRemoteNotifications()
        }
    }

    /// Calls APNs registration when authorization was already granted earlier.
    func registerForRemoteNotificationsIfAuthorized() async {
        let status = await authorizationStatus()
        if status == .authorized || status == .provisional || status == .ephemeral {
            registerForRemoteNotifications()
        }
    }
}
