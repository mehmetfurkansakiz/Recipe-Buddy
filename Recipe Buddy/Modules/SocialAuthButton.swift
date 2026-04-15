import SwiftUI

struct SocialAuthButton: View {
    enum Icon {
        case sfSymbol(String)
        case google
    }

    enum Style {
        case dark
        case light
        case google

        var background: Color {
            switch self {
            case .dark: return .black
            case .google: return .white
            case .light: return Color.Surface
            }
        }

        var foreground: Color {
            switch self {
            case .dark: return .white
            case .google: return Color(red: 60 / 255, green: 64 / 255, blue: 67 / 255)
            case .light: return .TextPrimary
            }
        }

        var border: Color {
            switch self {
            case .dark: return .black.opacity(0.2)
            case .google: return Color(red: 218 / 255, green: 220 / 255, blue: 224 / 255)
            case .light: return .SurfaceBorder
            }
        }
    }

    let title: String
    let icon: Icon
    let style: Style
    let action: () -> Void
    var isDisabled: Bool = false
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if style == .google {
                    Spacer(minLength: 0)
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(
                                tint: style == .dark ? .white : style.foreground
                            )
                        )
                        .frame(width: 18, height: 18)
                } else {
                    iconView
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

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .sfSymbol(let systemName):
            Image(systemName: systemName)
                .font(.headline)
                .frame(width: 18)
        case .google:
            Image("google.icon")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 18, height: 18)
        }
    }
}
