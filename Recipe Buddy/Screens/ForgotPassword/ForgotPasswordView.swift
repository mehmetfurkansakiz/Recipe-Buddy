import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    var onNavigateToLogin: () -> Void

    @FocusState private var focusedField: Int?

    var body: some View {
        ZStack {
            Color.Background.ignoresSafeArea().onTapGesture { endEditing() }

            ScrollView {
                VStack(spacing: 20) {
                    VStack {
                        Text("Şifreni Sıfırla")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundStyle(.TextPrimary)

                        Text(stepDescription)
                            .font(.subheadline)
                            .foregroundStyle(.TextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 12)

                    switch viewModel.step {
                    case .request:
                        AuthTextField(placeholder: "E-posta Adresi", text: $viewModel.email)
                            .keyboardType(.emailAddress)

                        AuthButton(
                            title: "Sıfırlama Kodu Gönder",
                            action: { Task { await viewModel.sendResetOTP() } },
                            isDisabled: !viewModel.isFormValid || viewModel.isLoading,
                            isLoading: viewModel.isLoading
                        )
                        .padding(.top, 8)

                    case .verify:
                        AuthTextField(placeholder: "E-posta Adresi", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .disabled(true)
                            .opacity(0.8)

                        otpInputView

                        if viewModel.isTimerActive {
                            CircularTimerView(
                                progress: Double(viewModel.timeRemaining) / Double(viewModel.countdownDuration),
                                timeRemaining: viewModel.timeRemaining
                            )
                            .frame(width: 80, height: 80)
                            .padding(.top, 4)
                        } else {
                            Button("Kodu Tekrar Gönder") {
                                Task { await viewModel.resendResetOTP() }
                            }
                            .fontWeight(.bold)
                            .tint(.AppPrimary)
                            .font(.footnote)
                        }

                        AuthButton(
                            title: "Kodu Doğrula",
                            action: { Task { await viewModel.verifyResetOTP() } },
                            isDisabled: !viewModel.isOTPValid || viewModel.isLoading,
                            isLoading: viewModel.isLoading
                        )
                        .padding(.top, 8)

                    case .reset:
                        SecureField("Yeni Şifre (en az 8 karakter)", text: $viewModel.newPassword)
                            .textContentType(.newPassword)
                            .textFieldStyle(CustomTextFieldStyle())

                        SecureField("Yeni Şifre (Tekrar)", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .textFieldStyle(CustomTextFieldStyle())

                        AuthButton(
                            title: "Şifreyi Güncelle",
                            action: { Task { await viewModel.updatePasswordAfterRecovery() } },
                            isDisabled: !viewModel.isNewPasswordValid || viewModel.isLoading,
                            isLoading: viewModel.isLoading
                        )
                        .padding(.top, 8)

                    case .success:
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.green)

                        Text("Şifren başarıyla güncellendi.")
                            .font(.headline)
                            .foregroundStyle(.TextPrimary)

                        AuthButton(
                            title: "Giriş Ekranına Dön",
                            action: onNavigateToLogin,
                            isDisabled: false,
                            isLoading: false
                        )
                    }

                    Spacer(minLength: 24)

                    if viewModel.step != .success {
                        Button("Giriş Ekranına Dön") {
                            onNavigateToLogin()
                        }
                        .fontWeight(.bold)
                        .tint(.AppPrimary)
                        .font(.footnote)

                        if viewModel.step != .request {
                            Button("Başa Dön") {
                                viewModel.resetFlow()
                            }
                            .fontWeight(.bold)
                            .tint(.AppPrimary)
                            .font(.footnote)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .alert("Bilgilendirme", isPresented: .constant(viewModel.noticeMessage != nil), actions: {
                Button("Tamam") { viewModel.noticeMessage = nil }
            }, message: {
                Text(viewModel.noticeMessage ?? "")
            })
            .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("Tamam") { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
        .onAppear {
            NotificationCenter.default.post(name: .passwordRecoveryFlowStateChanged, object: true)
        }
        .onDisappear {
            NotificationCenter.default.post(name: .passwordRecoveryFlowStateChanged, object: false)
        }
    }

    private var stepDescription: String {
        switch viewModel.step {
        case .request:
            return "Hesabına kayıtlı e-posta adresini gir. Sana 6 haneli bir sıfırlama kodu göndereceğiz."
        case .verify:
            return "E-postana gelen 6 haneli kodu girerek doğrulama işlemini tamamla."
        case .reset:
            return "Kod doğrulandı. Şimdi yeni şifreni güvenli şekilde belirleyebilirsin."
        case .success:
            return "Şifre sıfırlama işlemi tamamlandı."
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
                            .stroke(focusedField == index ? Color.AppPrimary : Color.SurfaceBorder, lineWidth: 1)
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
                        } else if index > 0 {
                            focusedField = index - 1
                        }
                    }
            }
        }
    }

    private func distributePastedText(_ text: String, from startIndex: Int) {
        let characters = Array(text)
        for i in 0..<characters.count {
            let currentIndex = startIndex + i
            if currentIndex < viewModel.codeLength {
                viewModel.otpCode[currentIndex] = String(characters[i])
            }
        }
        focusedField = min(startIndex + characters.count - 1, viewModel.codeLength - 1)
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
