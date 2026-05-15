import Foundation

// Get full URL for user's avatar image
extension User {
    func avatarPublicURL(width: Int = 120) -> URL? {
        guard let avatarPath = avatarUrl, !avatarPath.isEmpty else { return nil }

        let cloudfrontDomain = Secrets.cloudfrontDomain
        var urlString = "\(cloudfrontDomain)/\(avatarPath)"
        urlString += "?w=\(width)&q=80"

        return URL(string: urlString)
    }

    /// Best-effort detection for anonymized/deleted accounts returned by backend.
    /// This is a UI safeguard; backend should still hard-delete or null sensitive fields.
    var isLikelyDeletedOrAnonymized: Bool {
        let fullNameLower = (fullName ?? "").lowercased()
        let usernameLower = (username ?? "").lowercased()
        let emailLower = email.lowercased()

        if fullNameLower.contains("silin") || fullNameLower.contains("deleted") {
            return true
        }
        if usernameLower.hasPrefix("deleted") || usernameLower.contains("anon") {
            return true
        }
        if emailLower.contains("deleted") || emailLower.contains("anon") {
            return true
        }

        return false
    }
}
