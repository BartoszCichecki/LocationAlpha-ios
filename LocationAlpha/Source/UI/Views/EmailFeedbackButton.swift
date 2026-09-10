//
//  EmailFeedbackButton.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 03/12/2024.
//

import DeviceKit
import MessageUI
import OSLog
import SwiftUI

private let to = "locationalphaapp@gmail.com"
private let subject = "LocationAlpha Feedback"
private let messageHtml = """
<html>
<head/>
<body>
<b style="color:#4916FF;">What is your camera model?</b>
<br/>
<br/>
<br/>
<br/>
<b style="color:#4916FF;">What do you want to share?</b>
<br/>
<br/>
<br/>
<br/>
<p style="color:gray;">
<b>Device information</b>
<br/>
Version: \(Bundle.main.releaseVersionNumber) (\(Bundle.main.buildVersionNumber))
<br/>
Model: \(DeviceKit.Device.current.safeDescription)
<br/>
Bluetooth: \(BluetoothPermissionHelper.status)
<br/>
Location: \(LocationPermissionHelper.status)
<br/>
Low Power Mode: \(DeviceKit.Device.current.batteryState?.lowPowerMode == true ? "Yes" : "No")
<br/>
Storage: \(DeviceKit.Device.volumeAvailableCapacity ?? 0) / \(DeviceKit.Device.volumeTotalCapacity ?? 0)
</p>
</body>
</html>
"""

private let messagePlain = """
What is your camera model?




What do you want to share?




Device information<
Version: \(Bundle.main.releaseVersionNumber) (\(Bundle.main.buildVersionNumber))
Model: \(DeviceKit.Device.current.safeDescription)
Bluetooth: \(BluetoothPermissionHelper.status)
Location: \(LocationPermissionHelper.status)
Low Power Mode: \(DeviceKit.Device.current.batteryState?.lowPowerMode == true ? "Yes" : "No")
Storage: \(DeviceKit.Device.volumeAvailableCapacity ?? 0) / \(DeviceKit.Device.volumeTotalCapacity ?? 0)
"""

struct EmailFeedbackButton: View {
    @State private var isLoading = false
    @State private var isPresented = false
    @State private var data: Data?

    var body: some View {
        Button {
            isLoading = true
            Task {
                let log = try? OSLogStore(scope: .currentProcessIdentifier).export()
                data = log?
                    .map { "[\($0.date.formatted(date: .numeric, time: .standard))] [\($0.category)] \($0.description)" }
                    .joined(separator: "\n")
                    .data(using: .utf8)
                isLoading = false
                isPresented = true
            }
        } label: {
            HStack {
                Text("Share Feedback")
                Spacer()
                if isLoading {
                    SpinnerView()
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
        }
        .emailFeedback(isPresented: $isPresented, data: $data)
        .disabled(isLoading)
        .onChange(of: isPresented) { _, newIsPresented in
            guard !newIsPresented else { return }
            data = nil
        }
    }
}

private extension View {
    func emailFeedback(isPresented: Binding<Bool>, data: Binding<Data?>) -> some View {
        modifier(EmailFeedbackPresenter(isPresented: isPresented, data: data))
    }
}

@MainActor private struct EmailFeedbackPresenter: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var data: Data?

    func body(content: Content) -> some View {
        if MFMailComposeViewController.canSendMail() {
            content
                .sheet(isPresented: $isPresented) {
                    MailComposeView(data: $data)
                        .edgesIgnoringSafeArea(.all)
                }
        } else {
            content
                .alert(isPresented: $isPresented) {
                    Alert(
                        title: Text("Oops!"),
                        message: Text("Mail app must be configured on your phone to share feedback.")
                    )
                }
        }
    }
}

@MainActor private struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @Binding var data: Data?

    func makeCoordinator() -> MailComposeViewCoordinator {
        MailComposeViewCoordinator { presentationMode.wrappedValue.dismiss() }
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setToRecipients([to])
        vc.setMessageBody(messageHtml, isHTML: true)
        if let data {
            vc.addAttachmentData(data, mimeType: "plain/text", fileName: "locationalpha.log")
        }
        return vc
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

@MainActor private class MailComposeViewCoordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
    let didFinish: () -> Void

    init(didFinish: @escaping () -> Void) {
        self.didFinish = didFinish
    }

    func mailComposeController(_: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
        didFinish()
    }
}
