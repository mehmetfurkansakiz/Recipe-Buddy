import Foundation

enum AppNavigation: Hashable {
    case recipeDetail(Recipe)
    case recipeCreate
    case recipeEdit(Recipe)
    case profile
    case userProfile(User)
    case editProfile
    case favoriteRecipes
    case settings
    case changePassword
    case emailPreferences
    case notificationPreferences
    case themePreferences
    case helpCenter
    case sendFeedback
    case advancedSettings
    case deleteAccount
}
