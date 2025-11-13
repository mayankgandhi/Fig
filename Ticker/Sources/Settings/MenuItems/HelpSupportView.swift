//
//  HelpSupportView.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI
import MessageUI
import TickerCore

struct HelpSupportView: View {
    @State private var showMailCompose = false
    @State private var showMailUnavailableAlert = false
    
    private let supportEmail = "fig@mayankgandhi.com"
    private var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    var body: some View {
        NativeMenuListItem(
            icon: "envelope",
            title: "Help & Support",
            subtitle: "Get help or send feedback",
            iconColor: TickerColor.success
        ) {
            if canSendMail {
                showMailCompose = true
            } else {
                showMailUnavailableAlert = true
            }
        }
        .sheet(isPresented: $showMailCompose) {
            if canSendMail {
                MailComposeView(
                    recipients: [supportEmail],
                    subject: "fig - Help & Support",
                    onDismiss: { showMailCompose = false }
                )
            }
        }
        .alert("Mail Unavailable", isPresented: $showMailUnavailableAlert) {
            Button("Copy Email") {
                UIPasteboard.general.string = supportEmail
            }
            Button("Open Mail App") {
                if let url = URL(string: "mailto:\(supportEmail)?subject=fig%20-%20Help%20%26%20Support") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mail is not configured on this device. You can copy the email address or open the Mail app manually.\n\nEmail: \(supportEmail)")
        }
    }
}

// MARK: - Mail Compose Wrapper
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        // Double-check that mail is available before creating the view controller
        // This prevents crashes if mail becomes unavailable between the check and creation
        guard MFMailComposeViewController.canSendMail() else {
            // If mail is unavailable, dismiss immediately and return a placeholder
            // This should never happen due to the conditional sheet in HelpSupportView,
            // but we handle it gracefully to prevent crashes
            DispatchQueue.main.async {
                onDismiss()
            }
            // Create a basic instance - it won't be presented due to the conditional check
            let placeholder = MFMailComposeViewController()
            placeholder.mailComposeDelegate = context.coordinator
            return placeholder
        }
        
        // Mail is available, create and configure the view controller
        let mailCompose = MFMailComposeViewController()
        mailCompose.setToRecipients(recipients)
        mailCompose.setSubject(subject)
        mailCompose.mailComposeDelegate = context.coordinator
        return mailCompose
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            onDismiss()
        }
    }
}

#Preview {
    HelpSupportView()
}
