import Foundation
import Supabase

struct NotificationPreferences: Codable, Equatable {
    let userId: UUID
    var pushComments: Bool
    var pushFavorites: Bool
    var pushRecipeUpdates: Bool
    var pushMarketing: Bool
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case pushComments = "push_comments"
        case pushFavorites = "push_favorites"
        case pushRecipeUpdates = "push_recipe_updates"
        case pushMarketing = "push_marketing"
        case updatedAt = "updated_at"
    }
}

@MainActor
final class NotificationPreferencesService {
    static let shared = NotificationPreferencesService()

    private init() {}

    /// Fetches preferences for the current user. Returns nil if no row exists yet.
    func fetchPreferences() async throws -> NotificationPreferences? {
        guard let userId = try? await supabase.auth.session.user.id else { return nil }

        // Try direct table select first to avoid RPC dependency
        do {
            let prefs: NotificationPreferences = try await supabase
                .from("user_notification_preferences")
                .select("*")
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value
            return prefs
        } catch {
            // If not found, return nil. Other errors propagate.
            // Postgrest returns error for .single() when no rows; we treat that as nil.
            return nil
        }
    }

    /// Upserts preferences for the current user and returns the saved record.
    func updatePreferences(
        pushComments: Bool,
        pushFavorites: Bool,
        pushRecipeUpdates: Bool,
        pushMarketing: Bool
    ) async throws -> NotificationPreferences {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw URLError(.userAuthenticationRequired)
        }

        let payload: [String: AnyEncodable] = [
            "user_id": AnyEncodable(userId.uuidString),
            "push_comments": AnyEncodable(pushComments),
            "push_favorites": AnyEncodable(pushFavorites),
            "push_recipe_updates": AnyEncodable(pushRecipeUpdates),
            "push_marketing": AnyEncodable(pushMarketing)
        ]

        // Prefer Postgrest upsert with onConflict on user_id
        let saved: NotificationPreferences = try await supabase
            .from("user_notification_preferences")
            .upsert([payload], onConflict: "user_id")
            .select("*")
            .single()
            .execute()
            .value

        return saved
    }
}

/// A type-erased Encodable wrapper to build dynamic dictionaries for Postgrest upsert.
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) {
        _encode = value.encode
    }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
