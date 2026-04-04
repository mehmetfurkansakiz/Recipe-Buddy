import Foundation
import Supabase

struct AccountDeletionRequestRecord: Decodable {
    let id: Int
    let requestedAt: Date
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case requestedAt = "requested_at"
        case status
    }
}

@MainActor
final class AccountDeletionService {
    static let shared = AccountDeletionService()

    private init() {}

    /// Creates an authenticated account deletion request on backend.
    /// Expected RPC: request_account_deletion()
    func requestAccountDeletion() async throws {
        guard (try? await supabase.auth.session) != nil else {
            throw URLError(.userAuthenticationRequired)
        }

        do {
            try await supabase
                .rpc("request_account_deletion")
                .execute()
        } catch {
            print("❌ [AccountDeletionService] requestAccountDeletion error: \(error)")
            throw error
        }
    }

    /// Fetches the current user's pending deletion request if available.
    func fetchPendingDeletionRequest() async throws -> AccountDeletionRequestRecord? {
        guard let userId = try? await supabase.auth.session.user.id else {
            return nil
        }

        do {
            let request: AccountDeletionRequestRecord = try await supabase
                .from("account_deletion_requests")
                .select("id, requested_at, status")
                .eq("user_id", value: userId)
                .eq("status", value: "pending")
                .order("requested_at", ascending: false)
                .limit(1)
                .single()
                .execute()
                .value
            return request
        } catch {
            return nil
        }
    }

    /// Cancels a pending deletion request.
    func cancelDeletionRequest(requestId: Int) async throws {
        do {
            try await supabase
                .from("account_deletion_requests")
                .update(["status": "cancelled"])
                .eq("id", value: requestId)
                .eq("status", value: "pending")
                .execute()
        } catch {
            print("❌ [AccountDeletionService] cancelDeletionRequest error: \(error)")
            throw error
        }
    }
}
