import Foundation
import Supabase

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var username = ""
    @Published var confirmPassword = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didRegister = false
    
    @Published var authError: AuthError?
    
    var isSignUpFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !fullName.isEmpty && !username.isEmpty && password == confirmPassword && password.count >= 6
    }
    
    func signUp() async {
        guard isSignUpFormValid else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1) Preflight: Check if email already exists in our public.users table
            let emailCheckResponse = try await supabase
                .from("users")
                .select("id", count: .exact)
                .eq("email", value: email)
                .limit(1)
                .execute()

            if (emailCheckResponse.count ?? 0) > 0 {
                self.errorMessage = "Bu e‑posta ile zaten hesap var. Lütfen giriş yapın."
                return
            }

            // 2) Preflight: Check if username already exists
            let usernameCheckResponse = try await supabase
                .from("users")
                .select("id", count: .exact)
                .eq("username", value: username)
                .limit(1)
                .execute()

            if (usernameCheckResponse.count ?? 0) > 0 {
                self.errorMessage = "Bu kullanıcı adı zaten alınmış. Lütfen başka bir kullanıcı adı deneyin."
                return
            }

            // 3) Proceed with sign up. Include metadata for full_name and username
            let _ = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "full_name": .string(fullName),
                    "username": .string(username)
                ]
            )

            UserDefaults.standard.set(true, forKey: "consent_prompt_after_signup")
            self.didRegister = true
        } catch {
            self.authError = AuthError.from(supabaseError: error)
            print("❌ Sign Up Error: \(error)")
        }
    }

    @Published var didAuthenticate = false

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let redirectURL = URL(string: "com.mehmetfurkansakiz.Recipe-Buddy://auth-callback")
            _ = try await supabase.auth.signInWithOAuth(provider: .apple, redirectTo: redirectURL)
            UserDefaults.standard.set(true, forKey: "consent_prompt_after_login")
            didAuthenticate = true
        } catch {
            authError = AuthError.from(supabaseError: error)
            print("❌ Apple Sign In Error: \(error)")
        }
    }
}
