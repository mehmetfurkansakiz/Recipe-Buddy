import Foundation

extension Notification.Name {
    /// Notification posted when a recipe is deleted.
    static let recipeDeleted = Notification.Name("recipeDeletedNotification")
    /// Notification posted when a recipe is updated.
    static let recipeUpdated = Notification.Name("recipeUpdatedNotification")
    /// Notification posted when a recipe is created.
    static let recipeCreated = Notification.Name("recipeCreatedNotification")
    /// Notification posted when a recipe's favorite status changes.
    static let favoriteStatusChanged = Notification.Name("favoriteStatusChangedNotification")
    /// Notification posted when app should switch tab bar selection.
    static let appTabSelectionRequested = Notification.Name("appTabSelectionRequestedNotification")
    /// Notification posted when APNs device token is updated.
    static let apnsDeviceTokenUpdated = Notification.Name("apnsDeviceTokenUpdatedNotification")
    /// Notification posted to indicate whether password recovery flow is active.
    static let passwordRecoveryFlowStateChanged = Notification.Name("passwordRecoveryFlowStateChangedNotification")
}
