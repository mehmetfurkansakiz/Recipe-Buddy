import Foundation
import UIKit

enum FeedbackType: String, CaseIterable, Identifiable {
    case general
    case bug
    case suggestion

    var id: Self { self }

    var title: String {
        switch self {
        case .general: return "Genel"
        case .bug: return "Hata"
        case .suggestion: return "Öneri"
        }
    }
}

@MainActor
final class FeedbackViewModel: ObservableObject {
    @Published var selectedType: FeedbackType = .general
    @Published var message: String = ""

    let supportEmail: String = SupportInfo.supportEmail

    var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
        ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
        ?? "Uygulama"
    }

    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "\(version) (\(build))"
    }

    var subject: String {
        "Geri Bildirim - \(selectedType.title)"
    }

    var composedBody: String {
        let footer = "\n\n\nUygulama: \(appName)\nSürüm: \(appVersion)\nCihaz: \(UIDevice.current.model)\niOS: \(UIDevice.current.systemVersion)"
        return message + footer
    }

    func mailtoURL() -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let bodyEncoded = composedBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:\(supportEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
    }

    init() {}
}

#if DEBUG
@MainActor
struct _FeedbackViewModelPreviewHelper {
    static func make() -> FeedbackViewModel {
        FeedbackViewModel()
    }
}
#endif

