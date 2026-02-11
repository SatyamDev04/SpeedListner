//
//  AudioAmplifier.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 09/02/26.
//

import AVFAudio

final class VolumeBoostManager {

    static let shared = VolumeBoostManager()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()

    private var audioFile: AVAudioFile?

    var isBoostEnabled = false

    private init() {}

    func prepare(with url: URL) throws {
        stop()

        audioFile = try AVAudioFile(forReading: url)

        engine.attach(playerNode)
        engine.attach(mixer)

        engine.connect(playerNode, to: mixer, format: audioFile!.processingFormat)
        engine.connect(mixer, to: engine.mainMixerNode, format: audioFile!.processingFormat)

        mixer.outputVolume = isBoostEnabled ? 10.0 : 1.0

        try engine.start()
    }

    func play(from time: TimeInterval) {
        guard let file = audioFile else { return }

        let frame = AVAudioFramePosition(time * file.fileFormat.sampleRate)

        playerNode.stop()
        playerNode.scheduleSegment(
            file,
            startingFrame: frame,
            frameCount: AVAudioFrameCount(file.length - frame),
            at: nil
        )
        playerNode.play()
    }

    func pause() {
        playerNode.pause()
    }

    func stop() {
        playerNode.stop()
        engine.stop()
        engine.reset()
    }

    func setBoost(_ enabled: Bool) {
        isBoostEnabled = enabled
        mixer.outputVolume = enabled ? 10.0 : 1.0
        UserDefaults.standard.set(enabled, forKey: "volumeBoostEnabled")
    }
}
