import Foundation

// Payload for partial user profile updates (no NULL writes; omit fields by passing nil)
struct UserUpdatePayload: Codable {
    let full_name: String?
    let city: String?
    let show_city: Bool?
    let bio: String?
    let birth_date: Date?
    let show_birth_date: Bool?
    let avatar_url: String?
    let profession: String?
    let show_profession: Bool?

    enum CodingKeys: String, CodingKey {
        case full_name, city, show_city, bio, birth_date, show_birth_date, avatar_url, profession, show_profession
    }
}

// Payload for profile updates where you may explicitly set a column to NULL
// Double-optional semantics for avatar_url:
// - avatar_url == nil           => do not include key (no update)
// - avatar_url == .some(nil)    => include key with null to set DB column to NULL
// - avatar_url == .some("key")  => include key with a String value
struct UserUpdatePayloadWithNull: Codable {
    let full_name: String?
    let city: String?
    let show_city: Bool?
    let bio: String??
    let birth_date: Date?
    let show_birth_date: Bool?
    let avatar_url: String??
    let profession: String?
    let show_profession: Bool?

    enum CodingKeys: String, CodingKey {
        case full_name, city, show_city, bio, birth_date, show_birth_date, avatar_url, profession, show_profession
    }
}
