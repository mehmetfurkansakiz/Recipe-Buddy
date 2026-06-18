import SwiftUI

enum LanguageOption: String, CaseIterable, Identifiable {
    case system
    case turkish
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Sistem Dili"
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }

    var subtitle: String {
        switch self {
        case .system: return "Cihaz dilini kullan";
        case .turkish: return "Uygulamayı Türkçe kullan";
        case .english: return "Use the app in English";
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .turkish: return "textformat"
        case .english: return "textformat.abc"
        }
    }

    var locale: Locale {
        switch self {
        case .system: return .current
        case .turkish: return Locale(identifier: "tr")
        case .english: return Locale(identifier: "en")
        }
    }
}

@MainActor
final class LanguagePreferencesViewModel: ObservableObject {
    @Published var selected: LanguageOption = .system

    private let defaults = UserDefaults.standard
    private let key = "app_language_option"

    init() {
        load()
    }

    func load() {
        if let raw = defaults.string(forKey: key), let option = LanguageOption(rawValue: raw) {
            selected = option
        } else {
            selected = .system
        }
    }

    func save() {
        defaults.set(selected.rawValue, forKey: key)
        NotificationCenter.default.post(name: .languageChanged, object: selected)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

