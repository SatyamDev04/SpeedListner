//
//  BottomOptionsBar 2.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 21/11/25.
//

import UIKit


final class BottomOptionsBarPlaylist: UIView {

    var onRemoveFromFolder: (() -> Void)?
    var onMove: (() -> Void)?
    var onDeleteCompletely: (() -> Void)?
    var onCancel: (() -> Void)?

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 54/255, green: 0/255, blue: 80/255, alpha: 1)
    //    layer.cornerRadius = 18
        //clipsToBounds = true

        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        addButton(title: "Remove\nFrom Folder") { [weak self] in self?.onRemoveFromFolder?() }
        addButton(title: "Move") { [weak self] in self?.onMove?() }
        addButton(title: "Delete\nCompletely") { [weak self] in self?.onDeleteCompletely?() }
        addButton(title: "Cancel") { [weak self] in self?.onCancel?() }
    }

    private func addButton(title: String, destructive: Bool = false, action: @escaping () -> Void) {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        btn.titleLabel?.numberOfLines = 2
        btn.titleLabel?.textAlignment = .center
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = destructive ? UIColor(red: 160/255, green: 20/255, blue: 50/255, alpha: 1) : UIColor(red: 110/255, green: 24/255, blue: 136/255, alpha: 1)
        btn.tintColor = .white
        btn.layer.cornerRadius = 10
        btn.clipsToBounds = true
        btn.addAction(UIAction(handler: { _ in action() }), for: .touchUpInside)

        stack.addArrangedSubview(btn)
        btn.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    func present(in parent: UIView) {
        // Remove existing
        parent.subviews.compactMap({ $0 as? BottomOptionsBar }).forEach { $0.removeFromSuperview() }

        parent.addSubview(self)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            bottomAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.bottomAnchor),
            heightAnchor.constraint(equalToConstant: 96)
        ])

        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 40)
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
            self.alpha = 1
            self.transform = .identity
        }, completion: nil)
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.18, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: 20)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}
