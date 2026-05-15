import SwiftUI
import UIKit

// EndEditing keyboard extension
extension View {
    func endEditing() {
        // (TextField, SecureField etc.) resign first responder
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func shimmering() -> some View {
        self.modifier(ShimmerEffect())
    }
}

public extension View {
    /// Adds a gesture recognizer to the view that dismisses the keyboard when tapping anywhere outside input fields.
    func hideKeyboardOnTap() -> some View {
        self
            .overlay(
                Color.clear
                    .ignoresSafeArea(.keyboard)
                    .allowsHitTesting(false)
            )
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
            )
    }
    
}


struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1.5
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(.gray.opacity(0.3))
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .gray.opacity(0.3), location: phase),
                        .init(color: .gray.opacity(0.6), location: phase + 0.1),
                        .init(color: .gray.opacity(0.3), location: phase + 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1.5
                    }
                }
            )
            .mask(content)
    }
}

// MARK: - UINavigationBar Configuration
// Reusable bridge to configure UINavigationBar from SwiftUI
struct NavigationBarConfigurator: UIViewControllerRepresentable {
    let configure: (UINavigationController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            if let nav = controller.navigationController {
                configure(nav)
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension View {
    // Applies an inline navigation bar style with custom title color/font and optional hide-on-swipe
    func inlineColoredNavigationBar(
        titleColor: Color,
        tintColor: Color = .AppPrimary,
        textStyle: UIFont.TextStyle = .headline,
        weight: UIFont.Weight = .bold,
        hidesOnSwipe: Bool = true,
        transparentBackground: Bool = true,
        showBackButtonTitle: Bool = false,
        backButtonTitle: String = "Geri"
    ) -> some View {
        self
            .toolbarTitleDisplayMode(.inline)
            .toolbarBackground(.automatic, for: .navigationBar)
            .background(
                NavigationBarConfigurator { nav in
                    nav.navigationBar.prefersLargeTitles = false
                    nav.hidesBarsOnSwipe = hidesOnSwipe

                    let appearance = UINavigationBarAppearance()
                    if transparentBackground {
                        appearance.configureWithTransparentBackground()
                        appearance.backgroundColor = .clear
                        appearance.shadowColor = .clear
                    } else {
                        appearance.configureWithDefaultBackground()
                    }

                    // Title Text Color and Font
                    let base = UIFont.preferredFont(forTextStyle: textStyle)
                    let font = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
                    let scaledFont = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)

                    appearance.titleTextAttributes = [
                        .foregroundColor: UIColor(titleColor),
                        .font: scaledFont
                    ]

                    // Button ve icon colors
                    let tint = UIColor(tintColor)

                    // Butonların yazı rengi
                    let buttonAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: tint]
                    
                    appearance.buttonAppearance.normal.titleTextAttributes = buttonAttributes
                    appearance.buttonAppearance.highlighted.titleTextAttributes = buttonAttributes
                    
                    appearance.doneButtonAppearance.normal.titleTextAttributes = buttonAttributes
                    appearance.doneButtonAppearance.highlighted.titleTextAttributes = buttonAttributes
                    
                    appearance.backButtonAppearance.normal.titleTextAttributes = buttonAttributes
                    appearance.backButtonAppearance.highlighted.titleTextAttributes = buttonAttributes

                    // glass/transparent nav bar'da geri oku tint'i düşebildiği için
                    // back indicator image'i doğrudan istediğimiz renkle veriyoruz.
                    let backIndicator = UIImage(systemName: "chevron.backward")?
                        .withTintColor(tint, renderingMode: .alwaysOriginal)
                    appearance.setBackIndicatorImage(backIndicator, transitionMaskImage: backIndicator)

                    // genel tintColor
                    nav.navigationBar.tintColor = tint
                    
                    // appearance usage
                    nav.navigationBar.standardAppearance = appearance
                    nav.navigationBar.compactAppearance = appearance
                    nav.navigationBar.scrollEdgeAppearance = appearance
                    
                    // Back Button Configuration
                    if showBackButtonTitle {
                        if let backItem = nav.navigationBar.backItem {
                            let backButton = UIBarButtonItem(title: backButtonTitle, style: .plain, target: nil, action: nil)
                            backItem.backBarButtonItem = backButton
                        }
                    } else {
                        if let topVC = nav.topViewController {
                            let backButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                            backButton.tintColor = tint
                            topVC.navigationItem.backBarButtonItem = backButton
                        }
                    }
                }
            )
    }
}
