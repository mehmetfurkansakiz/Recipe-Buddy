import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    var onRegisterSuccess: (String) -> Void
    var onNavigateToLogin: () -> Void
    var onAuthSuccess: () -> Void
    
    var body: some View {
        ZStack {
            Color.Background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack {
                        Text("Aramıza Katıl")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.TextPrimary)
                        Text("Yeni bir hesap oluşturarak tariflerini kaydet")
                            .font(.subheadline)
                            .foregroundStyle(.TextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // registration form
                    VStack(spacing: 16) {
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
                    
                    // navigate to login
                    HStack(spacing: 4) {
                        Text("Zaten bir hesabın var mı?")
                        Button("Giriş Yap") {
                            onNavigateToLogin()
                        }
                        .fontWeight(.bold)
                        .tint(.AppPrimary)
                    }
                    .font(.footnote)
                    .padding(.bottom)
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
                .onTapGesture {
                    endEditing()
                }
            }
        }
    }
}

#Preview {
    RegisterView(onRegisterSuccess: {_ in }, onNavigateToLogin: {}, onAuthSuccess: {})
}

