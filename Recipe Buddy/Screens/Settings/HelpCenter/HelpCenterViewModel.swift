import Foundation
import UIKit

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

@MainActor
final class HelpCenterViewModel: ObservableObject {
    // Static content (can be fetched in future)
    let faqItems: [FAQItem] = [
        .init(question: "Hesabımı nasıl doğrularım?", answer: "E-posta adresine gönderilen 6 haneli kodu uygulamada E-posta Doğrulama ekranına girerek doğrulayabilirsin."),
        .init(question: "Şifremi unuttum, ne yapmalıyım?", answer: "Giriş ekranındaki 'Şifremi Unuttum' bağlantısına dokun. E-postana gelen sıfırlama bağlantısı ile yeni şifre belirleyebilirsin."),
        .init(question: "Bildirim tercihlerini nasıl değiştirebilirim?", answer: "Ayarlar > Bildirim Tercihleri bölümünden pazarlama ve uygulama bildirimlerini özelleştirebilirsin."),
        .init(question: "Veri izinlerimi nereden yönetirim?", answer: "Ayarlar > Veri İzni ekranından Analitik, Çökme Raporları, Kişiselleştirme ve Pazarlama izinlerini dilediğin zaman güncelleyebilirsin.")
    ]

    // Configurable resources
    let supportEmail: String = SupportInfo.supportEmail
    let privacyPolicyURL: URL = SupportInfo.privacyPolicyURL
    let termsURL: URL = SupportInfo.termsURL

    // App info
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

    func mailtoURL(subject: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let body = "\n\n\nUygulama: \(appName)\nSürüm: \(appVersion)\nCihaz: \(UIDevice.current.model)\niOS: \(UIDevice.current.systemVersion)"
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "mailto:\(supportEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
    }
}
