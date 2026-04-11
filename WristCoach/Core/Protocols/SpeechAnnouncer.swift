import AVFoundation
import AVAudioSession

protocol SpeechAnnouncer {
    func say(_ text: String)
    func prewarm()
}

final class AVSpeechSynthesizerAnnouncer: SpeechAnnouncer {
    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()

    init() {
        configureAudioSession()
    }

    func say(_ text: String) {
        guard synthesizer.isPaused == false else {
            synthesizer.continueSpeaking()
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5

        synthesizer.speak(utterance)
    }

    func prewarm() {
        let utterance = AVSpeechUtterance(string: "test")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    private func configureAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            // Audio session config failed - log and continue
        }
    }
}
