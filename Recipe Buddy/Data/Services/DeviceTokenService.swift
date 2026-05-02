import Foundation
import Supabase

@MainActor
final class DeviceTokenService {
    static let shared = DeviceTokenService()
    private init() {}

    private let tokenKey = "apns_device_token"

    func syncStoredTokenIfPossible() async {
        guard let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty else { return }
        try? await upsertCurrentDeviceToken(token: token)
    }

    func upsertCurrentDeviceToken(token: String) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw URLError(.userAuthenticationRequired)
        }

        let payload: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId.uuidString),
            "device_token": AnyEncodable(token),
            "platform": AnyEncodable("ios"),
            "is_active": AnyEncodable(true),
            "updated_at": AnyEncodable(Date().ISO8601Format())
        ]

        _ = try await supabase
            .from("user_device_tokens")
            .upsert([payload], onConflict: "device_token")
            .execute()
    }
}

