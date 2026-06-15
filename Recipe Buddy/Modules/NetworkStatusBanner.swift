import SwiftUI
import Network

@MainActor
final class NetworkStatusMonitor: ObservableObject {
    @Published var isConnected = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "RecipeBuddy.NetworkMonitor")
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

struct NetworkStatusBanner: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let isConnected: Bool
    var retryButtonTitle: String = "Tekrar Dene"
    var onRetry: (() -> Void)? = nil
    
    var body: some View {
        if !isConnected {
            VStack(spacing: 10) {
                Label("İnternet bağlantısı yok", systemImage: "wifi.slash")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black.opacity(0.85))
                
                Text("Bağlantıyı kontrol edip tekrar deneyin.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.72) : Color.black.opacity(0.6))
                
                if let onRetry {
                    Button(retryButtonTitle) {
                        onRetry()
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.AppPrimary)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.26) : Color.white.opacity(0.58))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.36), lineWidth: 1)
            )
            .padding(.top, 8)
        }
    }
}
