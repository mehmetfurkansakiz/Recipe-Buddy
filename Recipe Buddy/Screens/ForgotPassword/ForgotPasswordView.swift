import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    var onNavigateToLogin: () -> Void

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea().onTapGesture { endEditing() }

            VStack(spacing: 20) {
                // Title and Description
                VStack {
                    Text("Şifreni Sıfırla")
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundStyle(.TextPrimary)
                    Text("Hesabına kayıtlı e-posta adresini girerek şifreni sıfırlayabilirsin.")
                        .font(.subheadline)
                        .foregroundStyle(.TextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                // Form
                AuthTextField(placeholder: "E-posta Adresi", text: $viewModel.email)
                    .keyboardType(.emailAddress)

                // Button or Timer
                if viewModel.isTimerActive {
                    // if timer is active, show the circular timer
                    CircularTimerView(
                        progress: Double(viewModel.timeRemaining) / Double(viewModel.countdownDuration),
                        timeRemaining: viewModel.timeRemaining
                    )
                    .frame(width: 80, height: 80)
                    .padding(.top)
                } else {
                    // if timer is not active, show the button
                    AuthButton(
                        title: "Sıfırlama Bağlantısı Gönder",
                        action: { Task { await viewModel.sendResetLink() } },
                        isDisabled: !viewModel.isFormValid || viewModel.isLoading,
                        isLoading: viewModel.isLoading
                    )
                    .padding(.top)
                }
                
                Spacer()

                // Navigate to Login
                Button("Giriş Ekranına Dön") {
                    onNavigateToLogin()
                }
                .fontWeight(.bold)
                .tint(.AppPrimary)
                .font(.footnote)
                .padding(.bottom)
            }
            .padding(.horizontal, 24)
            .alert("Başarılı!", isPresented: $viewModel.didSendLink, actions: {
                Button("Tamam") {
                    viewModel.didSendLink = false
                    onNavigateToLogin() // Navigate back to login after success
                }
            }, message: {
                Text("Şifre sıfırlama bağlantısı e-posta adresine gönderildi. Lütfen gelen kutunu kontrol et.")
            })
            .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("Tamam") { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
    }
}

// MARK: - Circular Timer View

struct CircularTimerView: View {
    let progress: Double
    let timeRemaining: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 6)
                .foregroundColor(Color.gray.opacity(0.2))
            
            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .foregroundColor(.AppPrimary)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
            
            Text("\(timeRemaining)s")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.TextPrimary)
        }
    }
}

#Preview {
    ForgotPasswordView(onNavigateToLogin: {})
}
