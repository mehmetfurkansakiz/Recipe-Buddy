import Foundation
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

final class ConsentManager {
    static let shared = ConsentManager()
    private init() {}

    private let defaults = UserDefaults.standard

    // Keys aligned with DataConsentPreferencesViewModel
    private let kAnalytics = "consent_analytics"
    private let kCrash = "consent_crash"
    private let kPersonalization = "consent_personalization"
    private let kMarketing = "consent_marketing"
    private let kLastUpdated = "consent_last_updated"
    private let kConsentPromptSeen = "consent_prompt_seen_once"

    // MARK: - Read State
    func hasUserDecided() -> Bool {
        return defaults.object(forKey: kLastUpdated) != nil
    }

    func analyticsAllowed() -> Bool { defaults.bool(forKey: kAnalytics) }
    func crashReportsAllowed() -> Bool { defaults.bool(forKey: kCrash) }
    func personalizationAllowed() -> Bool { defaults.bool(forKey: kPersonalization) }
    func marketingAllowed() -> Bool { defaults.bool(forKey: kMarketing) }

    func needsGeneralConsent() -> Bool { !hasUserDecided() }

    // MARK: - Prompt Flow
    func hasSeenConsentPrompt() -> Bool {
        defaults.bool(forKey: kConsentPromptSeen)
    }

    func markConsentPromptSeen() {
        defaults.set(true, forKey: kConsentPromptSeen)
    }

    /// First-run prompt visibility: show only once regardless of user decision.
    func shouldShowConsentPromptOnce() -> Bool {
        !hasSeenConsentPrompt()
    }

    // MARK: - ATT (Tracking) for Ads/Personalization
    func requestTrackingAuthorizationIfNeeded() {
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14.5, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { _ in
                    // You may handle callbacks here if needed
                }
            }
        }
        #endif
    }

    // MARK: - Sync with Notification Preferences (Marketing)
    func syncMarketingPreferenceWithNotifications() async {
        // Only attempt if we have a decision stored
        guard hasUserDecided() else { return }
        let marketing = marketingAllowed()
        do {
            // Try to fetch current preferences
            if let current = try await NotificationPreferencesService.shared.fetchPreferences() {
                // Update only the marketing flag, keep others as-is
                _ = try await NotificationPreferencesService.shared.updatePreferences(
                    pushComments: current.pushComments,
                    pushFavorites: current.pushFavorites,
                    pushRecipeUpdates: current.pushRecipeUpdates,
                    pushMarketing: marketing
                )
            } else {
                // If no row exists yet, create one with defaults and marketing from consent
                _ = try await NotificationPreferencesService.shared.updatePreferences(
                    pushComments: true,
                    pushFavorites: true,
                    pushRecipeUpdates: true,
                    pushMarketing: marketing
                )
            }
        } catch {
            // Silently ignore errors here; UI will manage its own state elsewhere
            print("⚠️ ConsentManager: Failed to sync marketing preference: \(error)")
        }
    }
}
