//
//  LandscapePlayerViewController.swift
//  SpeedListner
//
//  Created by satyam dwivedi on 31/10/25.
//


import UIKit
import AVFoundation

final class LandscapePlayerViewController: UIViewController {

    // MARK: - UI references
    private let coverImageView = UIImageView()
    private let rewindButton = UIButton(type: .system)
    private let playButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let speedLabel = UILabel()
    private let escalationSwitch = UISwitch()
    private let bookmarkButton = UIButton(type: .system)

    // Keep a small state reference
    private var isPlaying: Bool {
        // adapt if your PlayerManager uses different property
        return (PlayerManager.shared.audioPlayer?.isPlaying ?? false)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        syncWithPlayer()
        subscribeToPlayerNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup
    private func configureUI() {
        view.backgroundColor = UIColor.systemBackground

        // Container split: left cover, right controls
        let leftContainer = UIView()
        let rightContainer = UIView()
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leftContainer)
        view.addSubview(rightContainer)

        NSLayoutConstraint.activate([
            leftContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            leftContainer.topAnchor.constraint(equalTo: view.topAnchor),
            leftContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leftContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),

            rightContainer.leadingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            rightContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            rightContainer.topAnchor.constraint(equalTo: view.topAnchor),
            rightContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Cover
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 8
        leftContainer.addSubview(coverImageView)
        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor, constant: 16),
            coverImageView.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor, constant: -16),
            coverImageView.centerYAnchor.constraint(equalTo: leftContainer.centerYAnchor),
            coverImageView.heightAnchor.constraint(lessThanOrEqualTo: leftContainer.heightAnchor, multiplier: 0.9)
        ])

        // Right side stack
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: rightContainer.centerYAnchor)
        ])

        // Control row (rewind - play - forward)
        let controlsRow = UIStackView()
        controlsRow.axis = .horizontal
        controlsRow.spacing = 24
        controlsRow.alignment = .center
        controlsRow.distribution = .equalCentering
        controlsRow.translatesAutoresizingMaskIntoConstraints = false

        styleCircleButton(rewindButton, systemName: "gobackward.10")
        styleCircleButton(playButton, systemName: "play.fill")
        styleCircleButton(forwardButton, systemName: "goforward.10")

        rewindButton.addTarget(self, action: #selector(rewindTapped), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)

        controlsRow.addArrangedSubview(rewindButton)
        controlsRow.addArrangedSubview(playButton)
        controlsRow.addArrangedSubview(forwardButton)

        // Speed row (- , label, +)
        let speedRow = UIStackView()
        speedRow.axis = .horizontal
        speedRow.spacing = 12
        speedRow.alignment = .center

        styleSmallCircle(minusButton, title: "-")
        styleSmallCircle(plusButton, title: "+")
        minusButton.addTarget(self, action: #selector(decreaseSpeed), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(increaseSpeed), for: .touchUpInside)

        speedLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        speedLabel.textAlignment = .center
        speedLabel.text = "\(PlayerManager.shared.currentSpeed)x"

        speedRow.addArrangedSubview(minusButton)
        speedRow.addArrangedSubview(speedLabel)
        speedRow.addArrangedSubview(plusButton)

        // Escalation + Bookmark row
        let toggleRow = UIStackView()
        toggleRow.axis = .horizontal
        toggleRow.spacing = 16
        toggleRow.alignment = .center

        escalationSwitch.isOn = PlayerManager.shared.speedEsalbutton
        escalationSwitch.addTarget(self, action: #selector(escalationToggled), for: .valueChanged)

        bookmarkButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        bookmarkButton.tintColor = UIColor.systemPurple
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)

        let escalationLabel = UILabel()
        escalationLabel.text = "Speed Escalation"
        escalationLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)

        toggleRow.addArrangedSubview(escalationLabel)
        toggleRow.addArrangedSubview(escalationSwitch)
        toggleRow.addArrangedSubview(bookmarkButton)

        // Add rows to main stack
        stack.addArrangedSubview(controlsRow)
        stack.addArrangedSubview(speedRow)
        stack.addArrangedSubview(toggleRow)

        // Fill cover image from current book if available (non-blocking)
        if let cover = (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController?.value(forKey: "coverImageView") as? UIImageView {
            coverImageView.image = cover.image
        } else {
            // fallback placeholder
            coverImageView.image = UIImage(named: "cover-placeholder")
        }
    }

    private func styleCircleButton(_ btn: UIButton, systemName: String) {
        btn.translatesAutoresizingMaskIntoConstraints = false
        if let img = UIImage(systemName: systemName) {
            btn.setImage(img.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        btn.tintColor = .white
        btn.backgroundColor = UIColor.systemPurple
        btn.layer.cornerRadius = 10
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 68),
            btn.heightAnchor.constraint(equalToConstant: 68)
        ])
    }

    private func styleSmallCircle(_ btn: UIButton, title: String) {
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor.systemPurple
        btn.layer.cornerRadius = 20
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 48),
            btn.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - Sync
    private func syncWithPlayer() {
        // Fill speed label and switch
        speedLabel.text = "\(PlayerManager.shared.currentSpeed)x"
        escalationSwitch.isOn = PlayerManager.shared.speedEsalbutton

        // Play button image
        let playing = isPlaying
        let playImageName = playing ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: playImageName), for: .normal)
    }

    private func subscribeToPlayerNotifications() {
        // Subscribe to notifications your app already posts when playback changes, speed changes etc.
        NotificationCenter.default.addObserver(self, selector: #selector(playerStateChanged), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerStateChanged), name: Notification.Name("PlayerRateChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerStateChanged), name: Notification.Name.AudiobookPlayer.reloadData, object: nil)
    }

    @objc private func playerStateChanged() {
        DispatchQueue.main.async {
            self.syncWithPlayer()
        }
    }

    // MARK: - Actions
    @objc private func rewindTapped() {
      //  PlayerManager.shared.rewindByAudioSeconds()
    }

    @objc private func playTapped() {
        PlayerManager.shared.playPause()
        syncWithPlayer()
    }

    @objc private func forwardTapped() {
    //    PlayerManager.shared.forwardByAudioSeconds()
    }

    @objc private func increaseSpeed() {
        let s = min(PlayerManager.shared.currentSpeed + 0.1, 10.0)
        PlayerManager.shared.currentSpeed = s
        // apply to PlayerManager
        if let setRate = PlayerManager.shared.perform(Selector(("setPlaybackRate:")), with: NSNumber(value: s)) {
            _ = setRate
        }
        speedLabel.text = String(format: "%.1fx", s)
    }

    @objc private func decreaseSpeed() {
        let s = max(PlayerManager.shared.currentSpeed - 0.1, 0.1)
        PlayerManager.shared.currentSpeed = s
        if let setRate = PlayerManager.shared.perform(Selector(("setPlaybackRate:")), with: NSNumber(value: s)) {
            _ = setRate
        }
        speedLabel.text = String(format: "%.1fx", s)
    }

    @objc private func escalationToggled() {
        PlayerManager.shared.speedEsalbutton = escalationSwitch.isOn
    }

    @objc private func bookmarkTapped() {
        // Post a notification or call known selector to add bookmark
        NotificationCenter.default.post(name: Notification.Name("AddBookmarkFromUI"), object: nil)
    }
}
