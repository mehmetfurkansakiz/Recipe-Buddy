import Foundation
import Supabase

enum AuthError: LocalizedError, Identifiable {
    var id: String { self.localizedDescription }
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case emailNotConfirmed
    case networkError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "E-posta veya şifre hatalı. Lütfen bilgilerinizi kontrol edip tekrar deneyin."
        case .emailAlreadyInUse:
            return "Bu e-posta adresi zaten kullanılıyor. Lütfen farklı bir e-posta adresi deneyin veya şifrenizi sıfırlayın."
        case .weakPassword:
            return "Şifreniz çok zayıf. Lütfen en az 6 karakterden oluşan daha güçlü bir şifre seçin."
        case .emailNotConfirmed:
            return "Hesabınız henüz onaylanmamış. Lütfen e-postanıza gönderilen 6 haneli kodu girerek hesabınızı onaylayın."
        case .networkError:
            return "İnternet bağlantınızda bir sorun var gibi görünüyor. Lütfen bağlantınızı kontrol edip tekrar deneyin."
        case .unknown(let error):
            // For debug
            print("Bilinmeyen Hata: \(error.localizedDescription)")
            let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            if !message.isEmpty, message != "The operation couldn’t be completed." {
                return message
            }
            return "Beklenmedik bir hata oluştu. Lütfen daha sonra tekrar deneyin."
        }
    }
    
    // Supabase'den gelen genel hatayı kendi özel hata tipimize çeviriyoruz.
    static func from(supabaseError: Error) -> AuthError {
        let description = supabaseError.localizedDescription.lowercased()
        
        if description.contains("email not confirmed") {
            return .emailNotConfirmed
        } else if description.contains("invalid login credentials") {
            return .invalidCredentials
        } else if description.contains("email address already in use") {
            return .emailAlreadyInUse
        } else if description.contains("password should be at least 6 characters") {
            return .weakPassword
        } else if let urlError = supabaseError as? URLError, urlError.code == .notConnectedToInternet {
            return .networkError(supabaseError)
        } else {
            return .unknown(supabaseError)
        }
    }
    
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials): return true
        case (.emailAlreadyInUse, .emailAlreadyInUse): return true
        case (.weakPassword, .weakPassword): return true
        case (.emailNotConfirmed, .emailNotConfirmed): return true
        case (.networkError, .networkError): return true
        case (.unknown, .unknown): return true
        default: return false
        }
    }
}
