import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: UUID
    let fullName: String?
    let email: String
    let username: String?
    let avatarUrl: String?
    let profession: String?
    let showProfession: Bool?
    let totalRatingPoints: Int?
    let totalRatingsReceived: Int?
    var city: String? = nil
    var showCity: Bool? = nil
    var bio: String? = nil
    var birthDate: Date? = nil
    var showBirthDate: Bool? = nil
    let emailNewsletter: Bool?
    let emailProductUpdates: Bool?
    let emailRecipeTips: Bool?

    enum CodingKeys: String, CodingKey {
        case id, username, email, profession, city, bio
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case showProfession = "show_profession"
        case totalRatingPoints = "total_rating_points"
        case totalRatingsReceived = "total_ratings_received"
        case showCity = "show_city"
        case birthDate = "birth_date"
        case showBirthDate = "show_birth_date"
        case emailNewsletter = "email_newsletter"
        case emailProductUpdates = "email_product_updates"
        case emailRecipeTips = "email_recipe_tips"
    }
}
