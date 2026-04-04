import SwiftUI

enum ThemeOption: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Sistem"
        case .light: return "Açık"
        case .dark: return "Koyu"
        }
    }

    var icon: String {
        switch self {
        case .system: return "gearshape"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
class ThemePreferencesViewModel: ObservableObject {
    @Published var selected: ThemeOption = .system
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    private let defaults = UserDefaults.standard
    private let key = "app_theme_option"

    init() {
        load()
    }

    func load() {
        if let raw = defaults.string(forKey: key), let opt = ThemeOption(rawValue: raw) {
            selected = opt
        } else {
            selected = .system
        }
    }

    func save() {
        isSaving = true
        errorMessage = nil
        defaults.set(selected.rawValue, forKey: key)
        isSaving = false
        // Notify app to update color scheme if it listens
        NotificationCenter.default.post(name: .themeChanged, object: selected)
    }
}

extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
}
