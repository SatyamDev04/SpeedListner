//
//  BottomSheetAudioPlayerVC.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 07/05/25.
//



import UIKit
import AVFoundation

class BottomSheetAudioPlayerVC: UIViewController {

    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var url: URL?
    var currentValue: Float = 0.1
    private var timeObserverToken: Any?

    private let playPauseButton = UIButton()
    private let rewindButton = UIButton()
    private let forwardButton = UIButton()
    private let speedIncreseButton = UIButton()
    private let speedDecreseButton = UIButton()
    private let speedLabel = UILabel()
    private let progressSlider = UISlider()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        if let url = url {
            setupPlayer(with: url)
        }
    }

    deinit {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
    }

    private func setupPlayer(with url: URL) {
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            guard let self = self,
                  let duration = self.playerItem?.duration.seconds,
                  duration > 0 else { return }

            let currentTime = time.seconds
            self.progressSlider.value = Float(currentTime / duration)
        }
    }

    private func setupUI() {
        playPauseButton.setImage(UIImage(named: "Group 4"), for: .normal)
        rewindButton.setImage(UIImage(named: "Player Controls"), for: .normal)
        forwardButton.setBackgroundImage(UIImage(named: "forword"), for: .normal)
        speedDecreseButton.setBackgroundImage(UIImage(named: "akar-icons_circle-minus-fill"), for: .normal)
        speedIncreseButton.setBackgroundImage(UIImage(named: "Vector-34"), for: .normal)

        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        rewindButton.addTarget(self, action: #selector(rewindTapped), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)
        speedDecreseButton.addTarget(self, action: #selector(decreaseTapped), for: .touchUpInside)
        speedIncreseButton.addTarget(self, action: #selector(increaseTapped), for: .touchUpInside)

        currentValue = PlayerManager.shared.speed
        speedLabel.text = "Speed: \(PlayerManager.shared.speed)x"
        speedLabel.textAlignment = .center
        speedLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        progressSlider.minimumValue = 0.0
        progressSlider.maximumValue = 1.0
        progressSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)

        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(speedLabel)
        view.addSubview(progressSlider)

        let stack = UIStackView(arrangedSubviews: [speedDecreseButton, rewindButton, playPauseButton, forwardButton, speedIncreseButton])
        stack.axis = .horizontal
        stack.spacing = 20
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            progressSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressSlider.bottomAnchor.constraint(equalTo: speedLabel.topAnchor, constant: -16),

            speedLabel.bottomAnchor.constraint(equalTo: stack.topAnchor, constant: -16),
            speedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.heightAnchor.constraint(equalToConstant: 50),
            rewindButton.widthAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        guard let duration = playerItem?.duration.seconds, duration > 0 else { return }
        let seekTime = CMTime(seconds: Double(sender.value) * duration, preferredTimescale: 1)
        player?.seek(to: seekTime)
    }

    @objc private func playPauseTapped() {
        guard let player = player else { return }
        if playPauseButton.currentImage == UIImage(named: "21") {
            player.pause()
            playPauseButton.setImage(UIImage(named: "Group 4"), for: .normal)
        } else {
            player.play()
            player.rate = PlayerManager.shared.speed
            playPauseButton.setImage(UIImage(named: "21"), for: .normal)
        }
    }

    @objc private func increaseTapped() {
        if currentValue <= 10 {
            currentValue += 0.1
            let currentValue1 = round(currentValue * 100) / 100.0
            setSpeed(currentValue: currentValue1)
        } else {
            print("Maximum speed reached.")
        }
    }

    @objc private func decreaseTapped() {
        if currentValue > 0.1 {
            currentValue -= 0.1
            let currentValue1 = round(currentValue * 100) / 100.0
            setSpeed(currentValue: currentValue1)
        } else {
            setSpeed(currentValue: 0.1)
            print("Minimum speed reached.")
        }
    }

    @objc private func rewindTapped() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player.seek(to: newTime)
    }

    @objc private func forwardTapped() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player.seek(to: newTime)
    }

    func setSpeed(currentValue: Float) {
        let roundedValue = round(currentValue * 100) / 100.0
        PlayerManager.shared.speed = roundedValue
        player?.rate = roundedValue
        speedLabel.text = "Speed: \(roundedValue)x"
        print("Speed set to:", String(format: "%.1f", roundedValue))
    }
}
