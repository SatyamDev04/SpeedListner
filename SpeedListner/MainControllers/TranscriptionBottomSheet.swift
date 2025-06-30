//
//  TranscriptionBottomSheet.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 08/05/25.
//


import UIKit
import MessageUI

class TranscriptionBottomSheet: UIViewController,MFMailComposeViewControllerDelegate {

    private let transcriptionText: String
    private let textView = UITextView()
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Transcription via Email", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.backgroundColor = UIColor(named: "VoilatColor")
        button.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    init(transcription: String) {
        self.transcriptionText = transcription
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTextView()
        sendButton.addTarget(self, action: #selector(sendEmailTapped), for: .touchUpInside)
    }

    private func setupTextView() {
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = transcriptionText
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textAlignment = .justified

        let stackView = UIStackView(arrangedSubviews: [textView, sendButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            sendButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func sendEmailTapped() {
        guard MFMailComposeViewController.canSendMail() else {
            print("Email is not configured.")
            return
        }

        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setSubject("Transcription")
        mail.setMessageBody(transcriptionText, isHTML: false)

        present(mail, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }

}
