import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var networkMonitor = NetworkStatusMonitor()
    @State private var currentNonce: String?
    @AppStorage("has_seen_login_welcome_copy") private var hasSeenLoginWelcomeCopy = false
    @Environment(\.colorScheme) private var colorScheme
    var onAuthSuccess: () -> Void
    var onNavigateToRegister: () -> Void
    var onNavigateToForgotPassword: () -> Void
    var onNavigateToConfirmation: (String) -> Void
    
    var body: some View {
        ZStack {
            authBackground
                .ignoresSafeArea()
                .onTapGesture { endEditing() }

            GeometryReader { proxy in
                Image("cupcake.welcome")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width * 2, height: proxy.size.height * 0.65)
                    .clipped()
                    .blur(radius: 12.0)
                    .opacity(colorScheme == .dark ? 1.0 : 0.82)
                    .position(x: proxy.size.width / 2, y: (proxy.size.height * 0.75) / 2)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 16) {
                Spacer(minLength: 0)

                VStack(spacing: 6) {
                    Text(welcomeTitle)
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundStyle(colorScheme == .dark ? .TextPrimary : Color(red: 0.20, green: 0.12, blue: 0.06))
                    Text(welcomeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(colorScheme == .dark ? .F_2_F_2_F_7 : Color(red: 0.42, green: 0.30, blue: 0.18))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color.black.opacity(0.34)
                                : Color.white.opacity(0.42)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    colorScheme == .dark
                                        ? Color.white.opacity(0.20)
                                        : Color.white.opacity(0.55),
                                    lineWidth: 1
                                )
                        )
                }
                
                NetworkStatusBanner(isConnected: networkMonitor.isConnected)
                
                // Login form
                VStack(spacing: 12) {
                    AuthTextField(placeholder: "E-posta Adresi", text: $viewModel.email, contentType: .emailAddress)
                        .keyboardType(.emailAddress)
                    AuthTextField(placeholder: "Şifre", text: $viewModel.password, isSecure: true, contentType: .password)
                }
                
                // Forgot password link
                HStack {
                    Spacer()
                    Button("Şifremi Unuttum?") {
                        onNavigateToForgotPassword()
                    }
                    .font(.footnote)
                    .tint(.AppPrimary)
                }
                
                AuthButton(
                    title: "Giriş Yap",
                    action: { Task { await viewModel.signIn() } },
                    isDisabled: !viewModel.isSignInFormValid,
                    isLoading: viewModel.isLoading
                )

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Rectangle().fill(Color.SurfaceBorder).frame(height: 1)
                        Text("veya")
                            .font(.footnote)
                            .foregroundStyle(.TextSecondary)
                        Rectangle().fill(Color.SurfaceBorder).frame(height: 1)
                    }

                    SocialAuthButton(
                        title: localizedGoogleButtonTitle,
                        icon: .google,
                        style: .google,
                        action: { Task { await viewModel.signInWithGoogle() } },
                        isDisabled: viewModel.isLoading,
                        isLoading: viewModel.isLoading
                    )
                    .frame(height: 50)

                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            guard let credential = authResults.credential as? ASAuthorizationAppleIDCredential else {
                                viewModel.authError = .unknown(NSError(domain: "AppleSignIn", code: -1))
                                return
                            }

                            guard let tokenData = credential.identityToken,
                                  let idToken = String(data: tokenData, encoding: .utf8) else {
                                viewModel.authError = .unknown(NSError(domain: "AppleSignIn", code: -2))
                                return
                            }

                            guard let currentNonce else {
                                viewModel.authError = .unknown(NSError(domain: "AppleSignIn", code: -3, userInfo: [NSLocalizedDescriptionKey: "Apple nonce üretilemedi. Lütfen tekrar deneyin."]))
                                return
                            }

                            Task {
                                await viewModel.signInWithApple(idToken: idToken, nonce: currentNonce)
                            }
                        case .failure(let error):
                            viewModel.authError = .unknown(error)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.7 : 1)
                }
                
                // Navigate to register
                Button(action: {
                    onNavigateToRegister()
                }) {
                    HStack(spacing: 4) {
                        Text("Hesabın yok mu?")
                        Text("Kayıt Ol")
                            .fontWeight(.bold)
                            .foregroundStyle(.AppPrimary)
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .onChange(of: viewModel.didAuthenticate) {
                    if viewModel.didAuthenticate {
                        DispatchQueue.main.async {
                            onAuthSuccess()
                        }   
                    }
                }
                .onChange(of: viewModel.shouldNavigateToConfirmation) {
                    if viewModel.shouldNavigateToConfirmation {
                        onNavigateToConfirmation(viewModel.email)
                        viewModel.shouldNavigateToConfirmation = false
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            .onAppear {
                hasSeenLoginWelcomeCopy = true
            }
            .alert(item: $viewModel.authError) { error in
                Alert(
                    title: Text("Hata"),
                    message: Text(error.errorDescription ?? "Bilinmeyen bir hata oluştu."),
                    dismissButton: .default(Text("Tamam"))
                )
            }
        }
    }
}

private extension LoginView {
    var authBackground: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.09, green: 0.09, blue: 0.11),
                        Color(red: 0.11, green: 0.10, blue: 0.09),
                        Color(red: 0.08, green: 0.07, blue: 0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.97, blue: 0.94),
                        Color(red: 0.97, green: 0.93, blue: 0.88),
                        Color(red: 0.95, green: 0.90, blue: 0.84)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    var welcomeTitle: String {
        hasSeenLoginWelcomeCopy ? "Tekrar Hoş Geldin!" : "Hoş Geldin!"
    }
    
    var welcomeSubtitle: String {
        hasSeenLoginWelcomeCopy ? "Kaldığın yerden devam et" : "Tatlı tarif yolculuğuna başlayalım"
    }
    
    var localizedGoogleButtonTitle: String {
        (Locale.preferredLanguages.first?.lowercased().hasPrefix("tr") ?? false)
            ? "Google ile Devam Et"
            : "Continue with Google"
    }

    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in UInt8.random(in: 0 ... 255) }
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    LoginView(onAuthSuccess: {}, onNavigateToRegister: {}, onNavigateToForgotPassword: {}, onNavigateToConfirmation: {_ in })
}
