import SwiftUI

struct SplashView: View {
    let coordinator: AppCoordinator
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var networkMonitor = NetworkStatusMonitor()
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(hex: "#1A1A1A") : Color(hex: "#FAFAFA"))
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                ZStack {
                    SprinkleDrop(color: Color(hex: "#D49A50"), xFraction: 0.40, delay: 0.0)
                    SprinkleDrop(color: Color(hex: "#F4A261"), xFraction: 0.50, delay: 0.45)
                    SprinkleDrop(color: Color(hex: "#E9C46A"), xFraction: 0.60, delay: 0.9)
                    
                    Circle()
                        .fill(
                            colorScheme == .dark
                                ? Color.black.opacity(0.22)
                                : Color.white.opacity(0.26)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.24), lineWidth: 1)
                        )
                        .frame(width: 192, height: 192)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.34 : 0.16), radius: 22, x: 0, y: 12)
                        .scaleEffect(isPulsing ? 1.035 : 0.965)
                        .animation(
                            .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                    
                    Image("cupcake.splash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 138, height: 138)
                        .clipShape(Circle())
                        .opacity(colorScheme == .dark ? 0.90 : 0.96)
                }
                .frame(width: 256, height: 256)
                
                VStack(spacing: 10) {
                    Text("Şeker ve Süslemeler")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#D49A50"))
                        .multilineTextAlignment(.center)
                    
                    Text("Her tarifte biraz daha mutluluk.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.60) : Color.black.opacity(0.58))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                NetworkStatusBanner(
                    isConnected: networkMonitor.isConnected,
                    onRetry: { coordinator.retryRouteEvaluation() }
                )
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            isPulsing = true
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if isConnected, coordinator.currentView == .splash {
                coordinator.retryRouteEvaluation()
            }
        }
    }
}

private struct SprinkleDrop: View {
    let color: Color
    let xFraction: CGFloat
    let delay: Double
    private let duration: Double = 1.8
    
    var body: some View {
        TimelineView(.animation) { context in
            let t = phase(from: context.date)
            
            Capsule()
                .fill(color)
                .frame(width: 10, height: 18)
                .position(
                    x: 256 * xFraction,
                    y: 36
                )
                .offset(y: yOffset(for: t))
                .rotationEffect(.degrees(rotation(for: t)))
                .opacity(opacity(for: t))
        }
    }
    
    private func phase(from date: Date) -> CGFloat {
        let raw = (date.timeIntervalSinceReferenceDate + delay)
            .truncatingRemainder(dividingBy: duration) / duration
        return CGFloat(raw)
    }
    
    private func yOffset(for t: CGFloat) -> CGFloat {
        if t <= 0.8 {
            let local = t / 0.8
            return (-100) + (110 * local)   // -100 -> 10
        }
        let local = (t - 0.8) / 0.2
        return 10 - (10 * local)            // 10 -> 0
    }
    
    private func rotation(for t: CGFloat) -> CGFloat {
        if t <= 0.8 {
            return 360 * (t / 0.8)          // 0 -> 360
        }
        return 360
    }
    
    private func opacity(for t: CGFloat) -> CGFloat {
        if t <= 0.5 {
            return t / 0.5                  // 0 -> 1
        }
        if t <= 0.8 {
            return 1
        }
        let local = (t - 0.8) / 0.2
        return 1 - local                    // 1 -> 0
    }
}

private extension Color {
    init(hex: String) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    SplashView(coordinator: AppCoordinator())
}
