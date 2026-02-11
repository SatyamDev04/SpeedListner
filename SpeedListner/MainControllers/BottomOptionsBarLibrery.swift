//
//  BottomOptionsBar.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 21/11/25.
//

import UIKit


class BottomOptionsBar: UIView {
    
    var onMove: (() -> Void)?
    var onRename: (() -> Void)?
    var onDelete: (() -> Void)?
    var onCancel: (() -> Void)?
    
    private let stack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor(red: 60/255, green: 0, blue: 80/255, alpha: 1)
        //layer.cornerRadius = 20
        //clipsToBounds = true
        
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
        
        addButton("Move") { self.onMove?() }
        addButton("Rename") { self.onRename?() }
        addButton("Delete") { self.onDelete?() }
        addButton("Cancel") { self.onCancel?() }
    }
    
    private func addButton(_ title: String, destructive: Bool = false, action: @escaping () -> Void) {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.backgroundColor = destructive ? UIColor(red: 120/255, green: 0, blue: 40/255, alpha: 1) :
                                            UIColor(red: 100/255, green: 0, blue: 120/255, alpha: 1)
        btn.tintColor = .white
        btn.layer.cornerRadius = 12
        btn.clipsToBounds = true
        
        btn.addAction(UIAction { _ in action() }, for: .touchUpInside)
        stack.addArrangedSubview(btn)
    }
    
    func present(in parent: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(self)
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            bottomAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.bottomAnchor),
            heightAnchor.constraint(equalToConstant: 96)
        ])
        
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 50)
        
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: 50)
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
