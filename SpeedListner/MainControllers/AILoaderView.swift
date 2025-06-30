//
//  AILoaderView.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 06/05/25.
//

import UIKit
class AILoaderView: UIView {
    
    private let backgroundView = UIView()
    private let animationView = UIActivityIndicatorView(style: .large)
    var messageLabel = UILabel()
  
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        
        backgroundView.frame = bounds
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundView)
        
        animationView.color = .cyan
        animationView.startAnimating()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(animationView)
       
      
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.boldSystemFont(ofSize: 14)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor, constant: -20),
            messageLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 16),
            messageLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor)
        ])
    }
    
    func show(in parent: UIView,msg:String?) {
        if let msg = msg {
           messageLabel.text = msg
        }
        self.frame = parent.bounds
        parent.addSubview(self)
    }

    func dismiss() {
        self.removeFromSuperview()
    }
}
