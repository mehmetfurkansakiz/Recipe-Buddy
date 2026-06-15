import SwiftUI

struct AuthenticationView: View {
    @State private var currentAuthScreen: AuthScreen = .login
    
    private var authSwitchAnimation: Animation {
        .easeInOut(duration: 0.3)
    }
    
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
                        withAnimation(authSwitchAnimation) {
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
                .transition(.opacity)
                .zIndex(currentAuthScreen == .login ? 1 : 0)
            }

            if currentAuthScreen == .register {
                RegisterView(
                    onRegisterSuccess: { email in
                        withAnimation(.easeInOut) {
                            currentAuthScreen = .emailConfirmation(email: email, isNewUser: true)
                        }
                    },
                    onNavigateToLogin: {
                        withAnimation(authSwitchAnimation) {
                            currentAuthScreen = .login
                        }
                    },
                    onAuthSuccess: onAuthSuccess
                )
                .transition(.opacity)
                .zIndex(currentAuthScreen == .register ? 1 : 0)
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
        .animation(authSwitchAnimation, value: currentAuthScreen)
    }
}

#Preview {
    AuthenticationView(onAuthSuccess: {})
}
