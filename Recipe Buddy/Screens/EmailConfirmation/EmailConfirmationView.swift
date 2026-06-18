import SwiftUI

struct EmailConfirmationView: View {
    @StateObject var viewModel: EmailConfirmationViewModel
    var onConfirmed: () -> Void
    var onNavigateBack: () -> Void
    var isNewUser: Bool
    
    @FocusState private var focusedField: Int?
    
    init(email: String, isNewUser: Bool, onConfirmed: @escaping () -> Void, onNavigateBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: EmailConfirmationViewModel(email: email))
        self.isNewUser = isNewUser
        self.onConfirmed = onConfirmed
        self.onNavigateBack = onNavigateBack
    }
    
    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea().onTapGesture { endEditing() }
            
            VStack(spacing: 30) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.AppPrimary)
                
                VStack(spacing: 12) {
                    Text("E-postanı Onayla")
                        .font(.largeTitle).fontWeight(.bold).foregroundStyle(.TextPrimary)
                    
                    Text("Lütfen e-posta adresine gönderdiğimiz 6 haneli kodu gir.")
                        .font(.subheadline).foregroundStyle(.TextSecondary).multilineTextAlignment(.center)
                }
                
                Text(viewModel.email)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.SurfaceBorder, lineWidth: 1))
                
                // 6 digit OTP Input
                otpInputView
                
                if viewModel.isTimerActive {
                    VStack {
                        Text("Tekrar göndermek için bekle:")
                            .font(.caption).foregroundStyle(.TextSecondary)
                        
                        CircularTimerView(
                            progress: Double(viewModel.timeRemaining) / Double(viewModel.countdownDuration),
                            timeRemaining: viewModel.timeRemaining
                        )
                        .frame(width: 80, height: 80)
                    }
                    .padding(.top)
                } else {
                    Button("Kodu Tekrar Gönder") {
                        Task { await viewModel.sendOTP() }
                    }
                    .fontWeight(.bold)
                    .tint(.AppPrimary)
                    .font(.footnote)
                }
                
                Spacer()
                
                // Doğrulama Butonu
                AuthButton(
                    title: "Onayla",
                    action: { Task { await viewModel.verifyOTP() } },
                    isDisabled: viewModel.isVerifyButtonDisabled,
                    isLoading: viewModel.isLoading
                )
                
                Button("Geri Dön") {
                    onNavigateBack()
                }
                .fontWeight(.bold)
                .tint(.AppPrimary)
                .font(.footnote)
                .padding(.bottom)
                
            }
            .padding(24)
            .alert("Bilgilendirme", isPresented: .constant(viewModel.noticeMessage != nil), actions: {
                Button("Tamam") { viewModel.noticeMessage = nil }
            }, message: { Text(LocalizedStringKey(viewModel.noticeMessage ?? "")) })
            .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("Tamam") { viewModel.errorMessage = nil }
            }, message: { Text(LocalizedStringKey(viewModel.errorMessage ?? "")) })
        }
        .onAppear {
            viewModel.onAppear(isNewUser: isNewUser)
        }
    }
    
    private var otpInputView: some View {
        HStack(spacing: 10) {
            ForEach(0..<viewModel.codeLength, id: \.self) { index in
                TextField("", text: $viewModel.otpCode[index])
                    .keyboardType(.numberPad)
                    .frame(width: 45, height: 55)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == index ? Color.AppPrimary : Color.SurfaceBorder , lineWidth: 1)
                    )
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .focused($focusedField, equals: index)
                    .tag(index)
                    .onChange(of: viewModel.otpCode[index]) {
                        let newText = viewModel.otpCode[index]
                        if newText.count > 1 {
                            viewModel.otpCode[index] = String(newText.prefix(1))
                            distributePastedText(newText, from: index)
                        } else if !newText.isEmpty {
                            if index < viewModel.codeLength - 1 {
                                focusedField = index + 1
                            } else {
                                focusedField = nil
                            }
                        } else {
                            if index > 0 {
                                focusedField = index - 1
                            }
                        }
                    }
            }
        }
    }
    
    // Copy paste
    private func distributePastedText(_ text: String, from startIndex: Int) {
        let characters = Array(text)
        for i in 0..<characters.count {
            let currentIndex = startIndex + i
            if currentIndex < viewModel.codeLength {
                viewModel.otpCode[currentIndex] = String(characters[i])
            }
        }
        // Son kutuya odaklan
        focusedField = min(startIndex + characters.count - 1, viewModel.codeLength - 1)
    }
}

#Preview {
    EmailConfirmationView(email: "mehmetfurkansakiz@gmail.com", isNewUser: false, onConfirmed: {}, onNavigateBack: {})
}
