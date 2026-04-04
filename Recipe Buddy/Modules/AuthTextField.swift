import SwiftUI

struct AuthTextField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var contentType: UITextContentType? = nil
    
    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(.TextSecondary))
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.TextSecondary))
            }
        }
        .padding()
        .tint(.AppPrimary)
        .autocapitalization(.none)
        .textContentType(contentType)
        .autocorrectionDisabled(true)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.SurfaceBorder.opacity(0.5))
                    .offset(y: 1)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.Surface)
            }
        )
    }
}

#Preview {
    AuthTextField(placeholder: "placeholder", text: Binding<String>(get: { "" }, set: { _ in }))
        .padding()
}
