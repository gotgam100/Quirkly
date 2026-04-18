//
//  MailView.swift
//  Quirkly
//
//  메일 작성 화면
//

import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?

    var subject: String
    var body: String
    let developerEmail = "yogotgam@gmail.com"

    static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.mailComposeDelegate = context.coordinator
            controller.setToRecipients([developerEmail])
            controller.setSubject(subject)
            controller.setMessageBody(body, isHTML: false)
            return controller
        } else {
            let alertController = UIAlertController(
                title: "메일을 보낼 수 없습니다",
                message: "기기에 메일 계정이 설정되지 않았습니다.\n\nquirkly.dev@example.com으로 직접 메일을 보내주세요.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                DispatchQueue.main.async {
                    self.isPresented = false
                }
            })
            return alertController
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, result: $result)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(isPresented: Binding<Bool>, result: Binding<Result<MFMailComposeResult, Error>?>) {
            _isPresented = isPresented
            _result = result
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            if let error = error {
                self.result = .failure(error)
            } else {
                self.result = .success(result)
            }
            DispatchQueue.main.async {
                self.isPresented = false
            }
        }
    }
}
