import SwiftUI
import MessageUI

/// A SwiftUI wrapper for `MFMailComposeViewController` to compose and send emails.
///
/// Usage:
/// ```swift
/// if MailComposerView.canSendMail() {
///     MailComposerView(subject: "Hello",
///                      body: "This is the email body.",
///                      toRecipients: ["example@example.com"])
/// }
/// ```
struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let toRecipients: [String]
    var onFinish: ((MFMailComposeResult) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailCompose = MFMailComposeViewController()
        mailCompose.setSubject(subject)
        mailCompose.setToRecipients(toRecipients)
        mailCompose.setMessageBody(body, isHTML: false)
        mailCompose.mailComposeDelegate = context.coordinator
        return mailCompose
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed during the lifecycle
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onFinish: onFinish)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let dismiss: DismissAction
        private let onFinish: ((MFMailComposeResult) -> Void)?
        
        init(dismiss: DismissAction, onFinish: ((MFMailComposeResult) -> Void)?) {
            self.dismiss = dismiss
            self.onFinish = onFinish
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            onFinish?(result)
            dismiss()
        }
    }
    
    /// Checks whether the current device is configured to send mail.
    /// - Returns: `true` if mail can be sent, otherwise `false`.
    static func canSendMail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }
}
