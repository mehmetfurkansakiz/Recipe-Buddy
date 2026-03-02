import Foundation
import Supabase

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    @Published var isLoading = false
    @Published var didAuthenticate = false
    @Published var authError: AuthError?
    
    @Published var shouldNavigateToConfirmation = false
    
    var isSignInFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    func signIn() async {
        guard isSignInFormValid else { return }
        
        isLoading = true
        shouldNavigateToConfirmation = false
        defer { isLoading = false }
        
        do {
            let _ = try await supabase.auth.signIn(email: email, password: password)
            
            UserDefaults.standard.set(true, forKey: "consent_prompt_after_login")
            self.didAuthenticate = true
        } catch {
            let specificError = AuthError.from(supabaseError: error)
            
            if specificError == .emailNotConfirmed {
                self.shouldNavigateToConfirmation = true
            } else {
                self.authError = specificError
            }
            print("❌ Sign In Error: \(error)")
        }
    }
}
