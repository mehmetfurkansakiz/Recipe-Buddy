import SwiftUI

struct AuthenticationView: View {
    @State private var currentAuthScreen: AuthScreen = .login
    
    var onAuthSuccess: () -> Void
    
    enum AuthScreen: Equatable {
        case login
        case register
        case forgotPassword
        case emailConfirmation(email: String, isNewUser: Bool)
    }

    var body: some View {
        ZStack {
            if currentAuthScreen == .login {
                LoginView(
                    onAuthSuccess: onAuthSuccess,
                    onNavigateToRegister: {
                        withAnimation(.easeInOut) {
                            currentAuthScreen = .register
                        }
                    },
                    onNavigateToForgotPassword: {
                        withAnimation(.easeInOut) {
                            currentAuthScreen = .forgotPassword
                        }
                    },
                    onNavigateToConfirmation: { email in
                        withAnimation(.easeInOut) {
                            currentAuthScreen = .emailConfirmation(email: email, isNewUser: false)
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            }

            if currentAuthScreen == .register {
                RegisterView(
                    onRegisterSuccess: { email in
                        withAnimation(.easeInOut) {
                            currentAuthScreen = .emailConfirmation(email: email, isNewUser: true)
                        }
                    },
                    onNavigateToLogin: {
                        withAnimation(.easeInOut) {
                            currentAuthScreen = .login
                        }
                    },
                    onAuthSuccess: onAuthSuccess
                )
                .transition(.move(edge: .trailing))
            }
            
            if currentAuthScreen == .forgotPassword {
                ForgotPasswordView(
                    onNavigateToLogin: {
                        withAnimation(.easeInOut) {
                            currentAuthScreen = .login
                        }
                    }
                )
                .transition(.move(edge: .trailing))
            }
            
            if case .emailConfirmation(let email, let isNewUser) = currentAuthScreen {
                EmailConfirmationView(
                    email: email, isNewUser: isNewUser, onConfirmed: onAuthSuccess, onNavigateBack: {
                        withAnimation(.easeInOut) {
                            currentAuthScreen = .login
                        }
                    }
                )
                .transition(.move(edge: .trailing))
            }
        }
    }
}

#Preview {
    AuthenticationView(onAuthSuccess: {})
}
