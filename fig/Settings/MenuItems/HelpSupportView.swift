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

    var body: some View {
        NativeMenuListItem(
            icon: "envelope",
            title: "Help & Support",
            subtitle: "Get help or send feedback",
            iconColor: TickerColor.success
        ) {
            showMailCompose = true
        }
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                recipients: ["fig@mayankgandhi.com"],
                subject: "fig - Help & Support",
                onDismiss: { showMailCompose = false }
            )
        }
    }
}

// MARK: - Mail Compose Wrapper
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
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
