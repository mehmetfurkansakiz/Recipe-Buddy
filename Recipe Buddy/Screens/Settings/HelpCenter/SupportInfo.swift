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
}
