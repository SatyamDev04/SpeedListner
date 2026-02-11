import AVFoundation
import AVKit

final class EngineAudioPlayer {

    static let shared = EngineAudioPlayer()

    private var audioFile: AVAudioFile?
    private var startFrame: AVAudioFramePosition = 0

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    private let eq = AVAudioUnitEQ(numberOfBands: 3)
    private let mixer = AVAudioMixerNode()

    private(set) var isPlaying = false
    private var isPausedState = false

    private init() {
        setup()
    }

    // MARK: - Setup
    private func setup() {
        engine.attach(playerNode)
        engine.attach(timePitch)
        engine.attach(eq)
        engine.attach(mixer)

        configureEQ()

        engine.connect(playerNode, to: timePitch, format: nil)
        engine.connect(timePitch, to: eq, format: nil)
        engine.connect(eq, to: mixer, format: nil)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)

        try? engine.start()
    }

    // MARK: - Load
    func load(url: URL) throws {
        stop()
        audioFile = try AVAudioFile(forReading: url)
        startFrame = 0
        isPausedState = false
    }

    // MARK: - Play
    func play(from time: TimeInterval) {
        guard let file = audioFile else { return }

       
        if isPausedState {
            playerNode.play()
            isPausedState = false
            isPlaying = true
            return
        }

        
        let sampleRate = file.processingFormat.sampleRate
        startFrame = AVAudioFramePosition(time * sampleRate)

        let remainingFrames = max(file.length - startFrame, 0)
        let frameCount = AVAudioFrameCount(remainingFrames)

        playerNode.stop()

        playerNode.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: frameCount,
            at: nil
        ) { [weak self] in
            DispatchQueue.main.async {
                self?.handlePlaybackFinished()
            }
        }

        playerNode.play()
        isPlaying = true
    }
    private func handlePlaybackFinished() {
        isPlaying = false
        isPausedState = false
        startFrame = 0

        NotificationCenter.default.post(
            name: Notification.Name("EnginePlaybackFinished"),
            object: nil
        )
    }
    // MARK: - Pause
    func pause() {
        guard isPlaying else { return }
        playerNode.pause()
        isPausedState = true
        isPlaying = false
    }

    // MARK: - Stop
    func stop() {
        playerNode.stop()
        isPlaying = false
        isPausedState = false
        startFrame = 0
    }

    // MARK: - Speed
    func setRate(_ rate: Float) {
        timePitch.rate = rate
        timePitch.pitch = 0
        timePitch.overlap = rate >= 4.0 ? 8.0 : 3.0
    }

    // MARK: - Boost
    func setBoost(enabled: Bool) {
        mixer.outputVolume = enabled ? 2.5 : 1.0
    }

    // MARK: - Current Time
    func currentTime() -> TimeInterval {
        guard
            let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime),
            let file = audioFile
        else { return 0 }

        let currentFrame = startFrame + AVAudioFramePosition(playerTime.sampleTime)
        return TimeInterval(currentFrame) / file.processingFormat.sampleRate
    }

    // MARK: - Duration
    func duration() -> TimeInterval {
        guard let file = audioFile else { return 0 }
        return TimeInterval(file.length) / file.processingFormat.sampleRate
    }

    // MARK: - EQ Setup
    private func configureEQ() {

        eq.bands[0].filterType = .highPass
        eq.bands[0].frequency = 120
        eq.bands[0].bypass = false

        eq.bands[1].filterType = .parametric
        eq.bands[1].frequency = 2800
        eq.bands[1].bandwidth = 1.0
        eq.bands[1].gain = 6.5
        eq.bands[1].bypass = false

        eq.bands[2].filterType = .highShelf
        eq.bands[2].frequency = 6000
        eq.bands[2].gain = 2.5
        eq.bands[2].bypass = false
    }
}
