//
//  ReportBugView.swift
//  fig
//
//  Created by Claude Code on 05/10/25.
//

import SwiftUI
import MessageUI
import TickerCore

struct ReportBugView: View {
    @State private var showMailCompose = false
    @State private var showMailUnavailableAlert = false
    
    private let supportEmail = "fig@mayankgandhi.com"
    private var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    var body: some View {
        NativeMenuListItem(
            icon: "ladybug.fill",
            title: "Report a Bug",
            subtitle: "Report issues or bugs",
            iconColor: TickerColor.danger
        ) {
            if canSendMail {
                showMailCompose = true
            } else {
                showMailUnavailableAlert = true
            }
        }
        .sheet(isPresented: $showMailCompose) {
            if canSendMail {
                BugReportMailComposeView(
                    recipients: [supportEmail],
                    subject: "fig - Bug Report",
                    onDismiss: { showMailCompose = false }
                )
            }
        }
        .alert("Mail Unavailable", isPresented: $showMailUnavailableAlert) {
            Button("Copy Email") {
                UIPasteboard.general.string = supportEmail
            }
            Button("Open Mail App") {
                if let url = URL(string: "mailto:\(supportEmail)?subject=fig%20-%20Bug%20Report") {
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
struct BugReportMailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        // Double-check that mail is available before creating the view controller
        // This prevents crashes if mail becomes unavailable between the check and creation
        guard MFMailComposeViewController.canSendMail() else {
            // If mail is unavailable, dismiss immediately and return a placeholder
            // This should never happen due to the conditional sheet in ReportBugView,
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
    ReportBugView()
}

