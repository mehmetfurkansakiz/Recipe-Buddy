import SwiftUI
import AuthenticationServices
import CryptoKit

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @State private var currentNonce: String?
    var onRegisterSuccess: (String) -> Void
    var onNavigateToLogin: () -> Void
    var onAuthSuccess: () -> Void
    
    var body: some View {
        ZStack {
            Color.Background
                .ignoresSafeArea()
                .onTapGesture { endEditing() }

            GeometryReader { proxy in
                Image("cupcake.welcome")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width * 2, height: proxy.size.height * 0.65)
                    .clipped()
                    .blur(radius: 12.0)
                    .position(x: proxy.size.width / 2, y: (proxy.size.height * 0.75) / 2)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .top)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack {
                        Text("Aramıza Katıl")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.TextPrimary)
                        Text("Yeni bir hesap oluşturarak tariflerini kaydet")
                            .font(.subheadline)
                            .foregroundStyle(.F_2_F_2_F_7)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // registration form
                    VStack(spacing: 12) {
                        AuthTextField(placeholder: "Tam Adınız", text: $viewModel.fullName, contentType: .name)
                        AuthTextField(placeholder: "Kullanıcı Adı", text: $viewModel.username, contentType: .username)
                        AuthTextField(placeholder: "E-posta Adresi", text: $viewModel.email, contentType: .emailAddress)
                            .keyboardType(.emailAddress)
                        AuthTextField(placeholder: "Şifre", text: $viewModel.password, isSecure: true, contentType: .oneTimeCode)
                        AuthTextField(placeholder: "Şifre (Tekrar)", text: $viewModel.confirmPassword, isSecure: true, contentType: .oneTimeCode)
                    }
                    
                    AuthButton(
                        title: "Hesap Oluştur",
                        action: { Task { await viewModel.signUp() } },
                        isDisabled: !viewModel.isSignUpFormValid,
                        isLoading: viewModel.isLoading
                    )
                    .padding(.top)

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
                    

                    
                    // navigate to login
                    Button(action: {
                        onNavigateToLogin()
                    }) {
                        HStack(spacing: 4) {
                            Text("Zaten bir hesabın var mı?")
                            Text("Giriş Yap")
                                .fontWeight(.bold)
                                .foregroundStyle(.AppPrimary)
                        }
                        .font(.footnote)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 28)
                    .onChange(of: viewModel.didRegister) {
                        if viewModel.didRegister {
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(true, forKey: "consent_prompt_after_signup")
                                onRegisterSuccess(viewModel.email)
                            }
                        }
                    }
                    .onChange(of: viewModel.didAuthenticate) {
                        if viewModel.didAuthenticate {
                            DispatchQueue.main.async {
                                onAuthSuccess()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .alert(item: $viewModel.authError) { error in
                    Alert(
                        title: Text("Hata"),
                        message: Text(error.errorDescription ?? "Bilinmeyen bir hata oluştu."),
                        dismissButton: .default(Text("Tamam"))
                    )
                }
                .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                    Button("Tamam") { viewModel.errorMessage = nil }
                }, message: {
                    Text(viewModel.errorMessage ?? "")
                })

            }
        }
    }
}

private extension RegisterView {
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
    RegisterView(onRegisterSuccess: {_ in }, onNavigateToLogin: {}, onAuthSuccess: {})
}
