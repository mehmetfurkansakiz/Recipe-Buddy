import Foundation
import Combine
import Supabase

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    enum Step {
        case request
        case verify
        case reset
        case success
    }

    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var noticeMessage: String?

    @Published var step: Step = .request
    @Published var otpCode: [String]
    let codeLength = 6

    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""

    // Timer properties
    @Published var timeRemaining = 180
    @Published var isTimerActive = false
    private var timer: AnyCancellable?
    let countdownDuration = 180

    init() {
        self.otpCode = Array(repeating: "", count: codeLength)
    }

    var isFormValid: Bool {
        !email.isEmpty && email.contains("@")
    }

    var isOTPValid: Bool {
        otpCode.joined().count == codeLength
    }

    var isNewPasswordValid: Bool {
        newPassword.count >= 8 && newPassword == confirmPassword
    }

    func sendResetOTP() async {
        guard isFormValid else { return }

        isLoading = true
        errorMessage = nil
        noticeMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.resetPasswordForEmail(email)
            step = .verify
            otpCode = Array(repeating: "", count: codeLength)
            noticeMessage = "Şifre sıfırlama kodu gönderildi. Lütfen e-postanı kontrol et."
            startTimer(from: countdownDuration)
        } catch {
            errorMessage = String(
                format: NSLocalizedString("Şifre sıfırlama kodu gönderilemedi: %@", comment: ""),
                error.localizedDescription
            )
            print("❌ Forgot Password Error: \(error)")
        }
    }

    func resendResetOTP() async {
        guard !isTimerActive else { return }
        await sendResetOTP()
    }

    func verifyResetOTP() async {
        guard isOTPValid else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.verifyOTP(email: email, token: otpCode.joined(), type: .recovery)
            stopTimer()
            step = .reset
            noticeMessage = "Kod doğrulandı. Şimdi yeni şifreni belirleyebilirsin."
        } catch {
            errorMessage = "Girdiğiniz kod hatalı veya süresi dolmuş."
            print("❌ Recovery OTP Verify Error: \(error)")
        }
    }

    func updatePasswordAfterRecovery() async {
        guard isNewPasswordValid else {
            if newPassword.count < 8 {
                errorMessage = "Yeni şifre en az 8 karakter olmalıdır."
            } else if newPassword != confirmPassword {
                errorMessage = "Şifreler eşleşmiyor."
            }
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            step = .success
            noticeMessage = "Şifren başarıyla güncellendi."
        } catch {
            errorMessage = "Şifre güncellenemedi. Lütfen tekrar dene."
            print("❌ Password Update Error: \(error)")
        }
    }

    func resetFlow() {
        step = .request
        otpCode = Array(repeating: "", count: codeLength)
        newPassword = ""
        confirmPassword = ""
        stopTimer()
    }

    func startTimer(from startTime: Int) {
        stopTimer()
        isTimerActive = true
        timeRemaining = startTime

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stopTimer()
                }
            }
    }

    private func stopTimer() {
        isTimerActive = false
        timer?.cancel()
        timer = nil
    }
}
