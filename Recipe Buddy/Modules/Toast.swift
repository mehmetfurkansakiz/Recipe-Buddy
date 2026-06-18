import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var duration: TimeInterval = 2.0

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let text = message {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey(text))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.black.opacity(0.85))
                .clipShape(Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation { message = nil }
                    }
                }
            }
        }
        .animation(.spring(), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>, duration: TimeInterval = 2.0) -> some View {
        self.modifier(ToastModifier(message: message, duration: duration))
    }
}
