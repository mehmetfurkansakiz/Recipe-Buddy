import Foundation
import Combine
import Supabase

@MainActor
class EmailConfirmationViewModel: ObservableObject {
    @Published var email: String
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var noticeMessage: String?

    @Published var otpCode: [String]
    let codeLength = 6

    // Timer properties
    @Published var timeRemaining: Int = 180
    @Published var isTimerActive = false
    private var timer: AnyCancellable?
    let countdownDuration = 180

    private var lastOTPSentKey: String { "lastOTPSentTimestamp_\(email)" }

    var isVerifyButtonDisabled: Bool {
        otpCode.joined().count != codeLength || isLoading
    }

    // Detect if running inside Xcode SwiftUI Previews
    private var isRunningInPreview: Bool {
        if let previewFlag = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] {
            return previewFlag == "1" || !previewFlag.isEmpty
        }
        return ProcessInfo.processInfo.arguments.contains("XCODE_RUNNING_FOR_PREVIEWS")
    }

    init(email: String) {
        self.email = email
        self.otpCode = Array(repeating: "", count: codeLength)
    }

    func onAppear(isNewUser: Bool) {
        // Avoid performing network actions during SwiftUI previews
        guard !isRunningInPreview else { return }

        if isNewUser {
            Task { await sendOTP(isResend: false) }
        } else {
            let lastSent = UserDefaults.standard.object(forKey: lastOTPSentKey) as? Date ?? .distantPast
            let timeElapsed = Date().timeIntervalSince(lastSent)

            if timeElapsed >= Double(countdownDuration) {
                Task { await sendOTP(isResend: false) }
            } else {
                let remainingTime = countdownDuration - Int(timeElapsed)
                startTimer(from: remainingTime)
            }
        }
    }

    func sendOTP(isResend: Bool = true) async {
        // Short-circuit network calls in SwiftUI previews and simulate success
        if isRunningInPreview {
            DispatchQueue.main.async {
                self.noticeMessage = "Onay kodu gönderildi. Lütfen gelen kutunu ve spam klasörünü kontrol et."
            }
            return
        }

        guard !isTimerActive else { return }

        isLoading = true
        errorMessage = nil
        noticeMessage = nil
        defer { isLoading = false }

        do {
            // For signup email verification, request a SIGNUP-type OTP (6-digit code)
            try await supabase.auth.resend(email: email, type: .signup)

            handleOTPSentSuccessfully(isResend: isResend)
        } catch {
            let description = error.localizedDescription.lowercased()

            // Supabase can return security/cooldown style messages even when the flow is healthy.
            // Treat these as a successful send path from UX perspective and keep cooldown active.
            if description.contains("security") ||
                description.contains("you can only request this after") ||
                description.contains("too many requests") ||
                description.contains("rate limit") {
                noticeMessage = "Onay kodu e-posta adresine gönderildi. Lütfen gelen kutunu ve spam klasörünü kontrol et."
                startCooldownAfterOTPSend()
                return
            }

            self.errorMessage = String(
                format: NSLocalizedString("Onay kodu gönderilemedi: %@", comment: ""),
                error.localizedDescription
            )
            print("❌ Send OTP Error: \(error)")
        }
    }

    private func handleOTPSentSuccessfully(isResend: Bool) {
        noticeMessage = isResend
            ? "Onay kodu tekrar gönderildi. Lütfen gelen kutunu ve spam klasörünü kontrol et."
            : "Onay kodu gönderildi. Lütfen gelen kutunu ve spam klasörünü kontrol et."
        startCooldownAfterOTPSend()
    }

    private func startCooldownAfterOTPSend() {
        UserDefaults.standard.set(Date(), forKey: lastOTPSentKey)
        self.otpCode = Array(repeating: "", count: self.codeLength)
        startTimer(from: countdownDuration)
    }

    func verifyOTP() async {
        guard !isVerifyButtonDisabled else { return }

        isLoading = true
        errorMessage = nil
        let token = otpCode.joined()
        defer { isLoading = false }

        do {
            try await supabase.auth.verifyOTP(email: email, token: token, type: .signup)

            print("✅ OTP Başarıyla Doğrulandı.")
            stopTimer()
        } catch {
            print("❌ OTP Doğrulama Hatası: \(error)")
            self.errorMessage = "Girdiğiniz kod hatalı veya süresi dolmuş."
        }
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
