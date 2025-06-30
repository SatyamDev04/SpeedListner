//
//  BottomSheetViewController.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 27/11/24.
//

import Foundation
import UIKit

class BottomSheetViewController: UIViewController {
    var onActionSelected: ((ActionType) -> Void)?

    enum ActionType {
        case delete
        case move
        case cancel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        // Add a horizontal stack view for the options
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 16

        // Create buttons
        let deleteButton = createButton(title: "Delete", color: .white)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        let moveButton = createButton(title: "Move", color: .white)
        moveButton.addTarget(self, action: #selector(moveTapped), for: .touchUpInside)

        let cancelButton = createButton(title: "Cancel", color: .white)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        // Add buttons to the stack view
        [deleteButton, moveButton, cancelButton].forEach { stackView.addArrangedSubview($0) }

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Add constraints
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.topAnchor,constant: 50),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func createButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = .lightGray.withAlphaComponent(0.2)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        return button
    }

    @objc private func deleteTapped() {
        dismiss(animated: true) {
            self.onActionSelected?(.delete)
        }
    }

    @objc private func moveTapped() {
        dismiss(animated: true) {
            self.onActionSelected?(.move)
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.onActionSelected?(.cancel)
        }
    }
}




