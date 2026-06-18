import Foundation

@MainActor
class DataConsentPreferencesViewModel: ObservableObject {
    @Published var analyticsConsent: Bool = false
    @Published var crashReportsConsent: Bool = false
    @Published var personalizationConsent: Bool = false
    @Published var marketingConsent: Bool = false
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    private let analyticsKey = "consent_analytics"
    private let crashKey = "consent_crash"
    private let personalizationKey = "consent_personalization"
    private let marketingKey = "consent_marketing"
    private let lastUpdatedKey = "consent_last_updated"

    init() {
        load()
    }

    func load() {
        isLoading = true
        defer { isLoading = false }

        let defaults = UserDefaults.standard
        analyticsConsent = defaults.bool(forKey: analyticsKey)
        crashReportsConsent = defaults.bool(forKey: crashKey)
        personalizationConsent = defaults.bool(forKey: personalizationKey)
        marketingConsent = defaults.bool(forKey: marketingKey)
        lastUpdated = defaults.object(forKey: lastUpdatedKey) as? Date
    }

    func savePreferences() {
        isSaving = true
        errorMessage = nil

        let defaults = UserDefaults.standard
        defaults.set(analyticsConsent, forKey: analyticsKey)
        defaults.set(crashReportsConsent, forKey: crashKey)
        defaults.set(personalizationConsent, forKey: personalizationKey)
        defaults.set(marketingConsent, forKey: marketingKey)
        let now = Date()
        defaults.set(now, forKey: lastUpdatedKey)
        lastUpdated = now
        ConsentManager.shared.markConsentPromptSeen()

        isSaving = false
    }

    func acceptAll() {
        analyticsConsent = true
        crashReportsConsent = true
        personalizationConsent = true
        marketingConsent = true
        savePreferences()
    }

    func rejectAll() {
        analyticsConsent = false
        crashReportsConsent = false
        personalizationConsent = false
        marketingConsent = false
        savePreferences()
    }

    func handleMarketingConsentChanged(_ isEnabled: Bool) {
        savePreferences()
        guard isEnabled else { return }
        Task {
            await NotificationPermissionManager.shared.requestSystemPromptForUserIntentIfNeeded()
        }
    }

    var formattedLastUpdated: String? {
        guard let lastUpdated = lastUpdated else { return nil }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "d MMMM yyyy"
        let dateString = formatter.string(from: lastUpdated)
        return String(format: NSLocalizedString("last_updated_format", comment: ""), dateString)
    }
}
