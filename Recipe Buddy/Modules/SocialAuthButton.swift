import SwiftUI

struct SocialAuthButton: View {
    enum Style {
        case dark
        case light

        var background: Color {
            switch self {
            case .dark: return .black
            case .light: return Color.Surface
            }
        }

        var foreground: Color {
            switch self {
            case .dark: return .white
            case .light: return .TextPrimary
            }
        }

        var border: Color {
            switch self {
            case .dark: return .black.opacity(0.2)
            case .light: return .SurfaceBorder
            }
        }
    }

    let title: String
    let iconSystemName: String
    let style: Style
    let action: () -> Void
    var isDisabled: Bool = false
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(
                                tint: style == .dark ? .white : .TextPrimary
                            )
                        )
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: iconSystemName)
                        .font(.headline)
                        .frame(width: 18)
                }

                Text(title)
                    .fontWeight(.semibold)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(style.background)
            .foregroundStyle(style.foreground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.border, lineWidth: 1)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.7 : 1)
    }
}
