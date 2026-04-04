import Foundation

enum SupportInfo {
    /// Returns the support email address from Info.plist (key: "SupportEmail").
    /// Falls back to a sensible default if not provided.
    static var supportEmail: String {
        if let email = Bundle.main.object(forInfoDictionaryKey: "SupportEmail") as? String, !email.isEmpty {
            return email
        }
        return "help@recipebuddy.com.tr"
    }

    /// Returns privacy policy URL from Info.plist (key: "PrivacyPolicyURL").
    static var privacyPolicyURL: URL {
        if
            let value = Bundle.main.object(forInfoDictionaryKey: "PrivacyPolicyURL") as? String,
            let url = URL(string: value),
            !value.isEmpty
        {
            return url
        }
        return URL(string: "https://example.com/privacy")!
    }

    /// Returns terms of use URL from Info.plist (key: "TermsOfUseURL").
    static var termsURL: URL {
        if
            let value = Bundle.main.object(forInfoDictionaryKey: "TermsOfUseURL") as? String,
            let url = URL(string: value),
            !value.isEmpty
        {
            return url
        }
        return URL(string: "https://example.com/terms")!
    }
}
