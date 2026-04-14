import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    var onAuthSuccess: () -> Void
    var onNavigateToRegister: () -> Void
    var onNavigateToForgotPassword: () -> Void
    var onNavigateToConfirmation: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea().onTapGesture { endEditing() }
            
            VStack(spacing: 20) {
                
                VStack {
                    Image("welcome.chef")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 240)
                    Text("Tekrar Hoş Geldin!")
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundStyle(.TextPrimary)
                    Text("Kaldığın yerden devam et")
                        .font(.subheadline)
                        .foregroundStyle(.TextSecondary)
                }
                
                // Login form
                VStack(spacing: 16) {
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
                        title: "Apple ile Devam Et",
                        iconSystemName: "applelogo",
                        style: .dark,
                        action: { Task { await viewModel.signInWithApple() } },
                        isDisabled: viewModel.isLoading,
                        isLoading: viewModel.isLoading
                    )

                    SocialAuthButton(
                        title: "Google ile Devam Et (Yakında)",
                        iconSystemName: "globe",
                        style: .light,
                        action: {},
                        isDisabled: true
                    )
                }
                
                Spacer()
                Spacer()
                
                // Navigate to register
                HStack(spacing: 4) {
                    Text("Hesabın yok mu?")
                    Button("Kayıt Ol") {
                        onNavigateToRegister()
                    }
                    .fontWeight(.bold)
                    .tint(.AppPrimary)
                }
                .font(.footnote)
                .padding(.bottom)
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

#Preview {
    LoginView(onAuthSuccess: {}, onNavigateToRegister: {}, onNavigateToForgotPassword: {}, onNavigateToConfirmation: {_ in })
}
