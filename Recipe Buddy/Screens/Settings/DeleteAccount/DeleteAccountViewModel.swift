import Foundation

@MainActor
final class DeleteAccountViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var pendingRequest: AccountDeletionRequestRecord?
    @Published var errorMessage: String?

    private let service: AccountDeletionService
    private let reviewWindowDays = 14

    init() {
        self.service = .shared
    }

    var hasPendingRequest: Bool {
        pendingRequest != nil
    }

    var remainingDaysText: String {
        guard let pendingRequest else { return "" }
        let deadline = Calendar.current.date(byAdding: .day, value: reviewWindowDays, to: pendingRequest.requestedAt) ?? pendingRequest.requestedAt
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
        if remaining <= 0 {
            return "Talep süresi doldu. İşlem kısa süre içinde uygulanabilir."
        }
        return "Talep \(reviewWindowDays) gün sonunda işleme alınacaktır. Kalan süre: \(remaining) gün."
    }

    func loadPendingRequest() async {
        pendingRequest = try? await service.fetchPendingDeletionRequest()
    }

    func submitDeletionRequest() async {
        guard !isSubmitting, !hasPendingRequest else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await service.requestAccountDeletion()
            pendingRequest = try await service.fetchPendingDeletionRequest()
        } catch {
            errorMessage = "Hesap silme talebi gönderilemedi. Lütfen tekrar dene."
        }
    }

    func cancelDeletionRequest() async -> Bool {
        guard let requestId = pendingRequest?.id, !isSubmitting else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await service.cancelDeletionRequest(requestId: requestId)
            pendingRequest = nil
            return true
        } catch {
            errorMessage = "Talep iptal edilemedi. Lütfen tekrar dene."
            return false
        }
    }
}
