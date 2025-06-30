//
//  SummaryBottomSheetVC.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 08/05/25.
//


import UIKit
import MessageUI

class SummaryBottomSheetVC: UIViewController, MFMailComposeViewControllerDelegate {

    var summaryText: String = ""

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .justified
        return label
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Summary via Email", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor(named: "VoilatColor")
        button.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(summaryLabel)
        view.addSubview(sendButton)
       
        summaryLabel.text = summaryText
        setupLayout()
        sendButton.addTarget(self, action: #selector(sendEmailTapped), for: .touchUpInside)
    }

    private func setupLayout() {
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            summaryLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            summaryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            summaryLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            sendButton.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 20),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            sendButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }

    @objc private func sendEmailTapped() {
        guard MFMailComposeViewController.canSendMail() else {
            print("Email is not configured.")
            return
        }

        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setSubject("Transcription Summary")
        mail.setMessageBody(summaryText, isHTML: false)

        present(mail, animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}
