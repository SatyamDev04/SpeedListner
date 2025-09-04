//
//  BottomSheetAudioPlayerVC.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 07/05/25.
//



import AVFoundation
import UIKit

class BottomSheetAudioPlayerVC: UIViewController {

    
    var url: URL?
    var urls: [URL]?

    // Player
    var player: AVPlayer?
    var playerItem: AVPlayerItem?

    // Track state
    private var currentIndex: Int = 0
    var currentValue: Float = 0.1
    private var timeObserverToken: Any?
   
    private weak var timeObserverPlayer: AVPlayer?
    // UI
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

        if let urls = urls, !urls.isEmpty {
            currentIndex = 0
            setupPlayer(with: urls[currentIndex])
        } else if let url = url {
            setupPlayer(with: url)
        }
    }

    deinit {
        if let token = timeObserverToken, let owner = timeObserverPlayer {
            owner.removeTimeObserver(token)
        }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup Player
    private func setupPlayer(with url: URL) {
        // Remove old observer safely before creating new player
        if let token = timeObserverToken, let oldPlayer = timeObserverPlayer {
            oldPlayer.removeTimeObserver(token)
            timeObserverToken = nil
            timeObserverPlayer = nil
        }

        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Add slider sync observer
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            guard let self = self,
                  let duration = self.playerItem?.duration.seconds,
                  duration > 0 else { return }
            let currentTime = time.seconds
            self.progressSlider.value = Float(currentTime / duration)
        }
        timeObserverPlayer = player // 👈 Save the owner

        // Observe when finished
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(itemDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: playerItem)

        // Auto play
        player?.play()
        player?.rate = PlayerManager.shared.speed
        playPauseButton.setImage(UIImage(named: "21"), for: .normal)
    }


    @objc private func itemDidFinishPlaying() {
        // If multiple -> load next
        if let urls = urls, currentIndex < urls.count - 1 {
            currentIndex += 1
            setupPlayer(with: urls[currentIndex])
        } else {
            print("✅ All clips finished")
            playPauseButton.setImage(UIImage(named: "Group 4"), for: .normal)
        }
    }

    // MARK: - UI Setup
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

    // MARK: - Controls
    @objc private func sliderValueChanged(_ sender: UISlider) {
        guard let duration = playerItem?.duration.seconds, duration > 0 else { return }
        let seekTime = CMTime(seconds: Double(sender.value) * duration, preferredTimescale: 1)
        player?.seek(to: seekTime)
    }

    @objc private func playPauseTapped() {
        guard let player = player else { return }
        if player.timeControlStatus == .playing {
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
        }
    }

    @objc private func decreaseTapped() {
        if currentValue > 0.1 {
            currentValue -= 0.1
            let currentValue1 = round(currentValue * 100) / 100.0
            setSpeed(currentValue: currentValue1)
        } else {
            setSpeed(currentValue: 0.1)
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
    }
  
    

}
