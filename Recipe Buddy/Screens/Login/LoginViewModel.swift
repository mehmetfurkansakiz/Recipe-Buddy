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

    func signInWithApple(idToken: String, nonce: String?) async {
        isLoading = true
        shouldNavigateToConfirmation = false
        defer { isLoading = false }

        do {
            let credentials = OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
            _ = try await supabase.auth.signInWithIdToken(credentials: credentials)
            UserDefaults.standard.set(true, forKey: "consent_prompt_after_login")
            didAuthenticate = true
        } catch {
            authError = AuthError.from(supabaseError: error)
            print("❌ Apple Sign In Error: \(error)")
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        shouldNavigateToConfirmation = false
        defer { isLoading = false }

        do {
            let redirectURL = URL(string: "com.mehmetfurkansakiz.Recipe-Buddy://auth-callback")
            _ = try await supabase.auth.signInWithOAuth(provider: .google, redirectTo: redirectURL)
            UserDefaults.standard.set(true, forKey: "consent_prompt_after_login")
            didAuthenticate = true
        } catch {
            authError = AuthError.from(supabaseError: error)
            print("❌ Google Sign In Error: \(error)")
        }
    }
}
