import SwiftUI
import UserNotifications
import UIKit

@MainActor
class NotificationPreferencesViewModel: ObservableObject {
    // General push permission status (from system settings)
    @Published var pushEnabled: Bool = false
    @Published var isDenied: Bool = false

    // App-specific categories (synced with Supabase)
    @Published var pushComments: Bool = true
    @Published var pushFavorites: Bool = true
    @Published var pushRecipeUpdates: Bool = true
    @Published var pushMarketing: Bool = false

    // Style (reflected from system settings; displayed read-only in UI)
    @Published var soundEnabled: Bool = true
    @Published var badgesEnabled: Bool = true

    // UI State
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    private let defaults = UserDefaults.standard
    private var isInitialLoadCompleted = false

    init() {
        Task { await loadPreferences() }
    }

    /// Loads preferences from system (authorization) and Supabase (app-specific toggles).
    func loadPreferences() async {
        isLoading = true
        errorMessage = nil

        // Refresh iOS notification authorization & style settings
        await refreshSystemAuthorizationStatus()

        // Try to fetch from Supabase; if not available, fall back to cached defaults
        do {
            if let prefs = try await NotificationPreferencesService.shared.fetchPreferences() {
                pushComments = prefs.pushComments
                pushFavorites = prefs.pushFavorites
                pushRecipeUpdates = prefs.pushRecipeUpdates
                pushMarketing = prefs.pushMarketing

                // Cache locally for quick startup next time
                cacheToDefaults()
            } else {
                // No row yet for this user; use cached defaults or sensible defaults
                loadFromDefaultsOrDefaults()
            }
        } catch {
            // Network or auth error; use cached values
            loadFromDefaultsOrDefaults()
            errorMessage = "Ayarlar yüklenemedi. Çevrimdışı olabilir veya oturum geçersiz olabilir."
        }

        isLoading = false
        isInitialLoadCompleted = true
    }

    /// Saves preferences to Supabase and updates local cache.
    func savePreferences() {
        guard isInitialLoadCompleted, !isLoading else { return }
        isSaving = true
        errorMessage = nil

        let current = (pushComments, pushFavorites, pushRecipeUpdates, pushMarketing)

        Task {
            do {
                let updated = try await NotificationPreferencesService.shared.updatePreferences(
                    pushComments: current.0,
                    pushFavorites: current.1,
                    pushRecipeUpdates: current.2,
                    pushMarketing: current.3
                )
                // Reflect server-confirmed values (in case of server-side normalization)
                self.pushComments = updated.pushComments
                self.pushFavorites = updated.pushFavorites
                self.pushRecipeUpdates = updated.pushRecipeUpdates
                self.pushMarketing = updated.pushMarketing

                // Update local cache
                self.cacheToDefaults()
            } catch {
                self.errorMessage = "Kaydedilemedi. Lütfen tekrar deneyin."
                // Optionally, reload from server to avoid drift
                await self.loadPreferences()
            }
            self.isSaving = false
        }
    }

    func requestAuthorizationIfNeeded(enabling: Bool) {
        guard enabling else {
            // Cannot programmatically revoke. Suggest opening system settings.
            openSystemSettings()
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    Task { @MainActor [weak self] in
                        if let error = error {
                            self?.errorMessage = String(
                                format: NSLocalizedString("Bildirim izni alınamadı: %@", comment: ""),
                                error.localizedDescription
                            )
                        }
                        self?.pushEnabled = granted
                        await self?.refreshSystemAuthorizationStatus()
                    }
                }

            case .denied:
                Task { @MainActor [weak self] in
                    self?.errorMessage = "Bildirim izni kapalı. Lütfen Ayarlar'dan açın."
                    self?.openSystemSettings()
                }

            default:
                Task { @MainActor [weak self] in
                    await self?.refreshSystemAuthorizationStatus()
                }
            }
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    func refreshSystemAuthorizationStatus() async {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                // Resume the continuation immediately from the callback
                continuation.resume()
                // Hop to the main actor to update published properties
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let status = settings.authorizationStatus
                    self.pushEnabled = (status == .authorized || status == .provisional || status == .ephemeral)
                    self.isDenied = (status == .denied)
                    self.soundEnabled = settings.soundSetting == .enabled
                    self.badgesEnabled = settings.badgeSetting == .enabled
                }
            }
        }
    }

    // MARK: - Local Cache Helpers
    private func cacheToDefaults() {
        defaults.set(pushComments, forKey: "notif_pushComments")
        defaults.set(pushFavorites, forKey: "notif_pushFavorites")
        defaults.set(pushRecipeUpdates, forKey: "notif_pushRecipeUpdates")
        defaults.set(pushMarketing, forKey: "notif_pushMarketing")
    }

    private func loadFromDefaultsOrDefaults() {
        pushComments = defaults.object(forKey: "notif_pushComments") as? Bool ?? true
        pushFavorites = defaults.object(forKey: "notif_pushFavorites") as? Bool ?? true
        pushRecipeUpdates = defaults.object(forKey: "notif_pushRecipeUpdates") as? Bool ?? true
        pushMarketing = defaults.object(forKey: "notif_pushMarketing") as? Bool ?? false
    }
}
