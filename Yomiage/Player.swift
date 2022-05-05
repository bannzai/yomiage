import Combine
import SwiftUI
import AVFoundation
import MediaPlayer

final class Player: NSObject, ObservableObject {
  @Published var volume = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerVolume)
  @Published var rate = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerRate)
  @Published var pitch = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerPitch)

  @Published private(set) var playingArticle: Article?
  private var progress: Progress?

  let synthesizer = AVSpeechSynthesizer()
  var canceller: Set<AnyCancellable> = []

  override init() {
    super.init()

    $volume
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] volume in
        UserDefaults.standard.set(volume, forKey: UserDefaultsKeys.playerVolume)

        self?.reset()
      }.store(in: &canceller)
    $rate
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] rate in
        UserDefaults.standard.set(rate, forKey: UserDefaultsKeys.playerRate)

        self?.reset()
      }.store(in: &canceller)
    $pitch
      .debounce(for: 0.5, scheduler: DispatchQueue.main)
      .sink { [weak self] pitch in
        UserDefaults.standard.set(pitch, forKey: UserDefaultsKeys.playerPitch)

        self?.reset()
      }.store(in: &canceller)

    synthesizer.delegate = self
  }

  func speak(article: Article, title: String, text: String) {
    playingArticle = article

    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
      MPMediaItemPropertyTitle: title,
      MPNowPlayingInfoPropertyPlaybackRate: rate
    ]

    speak(text: text)
  }

  func stop() {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }

    playingArticle = nil
  }

  func setupRemoteTransportControls() {
    MPRemoteCommandCenter.shared().playCommand.addTarget { event in
      if !self.synthesizer.isPaused {
        return .commandFailed
      }

      self.synthesizer.continueSpeaking()
      return .success
    }
    MPRemoteCommandCenter.shared().pauseCommand.addTarget { event in
      if self.synthesizer.isPaused {
        return .commandFailed
      }

      self.synthesizer.pauseSpeaking(at: .immediate)
      return .success
    }
  }
}

private extension Player {
  func speak(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.volume = volume
    utterance.rate = rate
    utterance.pitchMultiplier = pitch

    synthesizer.speak(utterance)
  }

  func reset() {
    // NOTE: After update @Published property(volume,rate,pitch), other @Published property cannot be updated. So should run to the next run loop.
    DispatchQueue.main.async {
      // NOTE: Keep vlaue for avoid flushing after synthesizer.stopSpeaking -> speechSynthesizer(:didCancel).
      let _remainingText = self.progress?.remainingText

      // NOTE: call synthesizer.speak is not speaking and is broken synthesizer when synthesizer.isSpeaking
      guard self.synthesizer.isSpeaking else {
        return
      }
      self.synthesizer.stopSpeaking(at: .word)

      if let remainingText = _remainingText {
        self.speak(text: remainingText)
      }
    }
  }
}

extension Player {
  enum DefaultValues {
    static let volume: Float = 0.5
    static let rate: Float = 0.53
    static let pitch: Float = 1.0

    static func setup() {
      if !UserDefaults.standard.dictionaryRepresentation().keys.contains(UserDefaultsKeys.playerVolume) {
        UserDefaults.standard.set(volume, forKey: UserDefaultsKeys.playerVolume)
      }
      if !UserDefaults.standard.dictionaryRepresentation().keys.contains(UserDefaultsKeys.playerRate) {
        UserDefaults.standard.set(rate, forKey: UserDefaultsKeys.playerRate)
      }
      if !UserDefaults.standard.dictionaryRepresentation().keys.contains(UserDefaultsKeys.playerPitch) {
        UserDefaults.standard.set(pitch, forKey: UserDefaultsKeys.playerPitch)
      }
    }
  }
}

extension Player: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    print(#function)

    progress = nil
    playingArticle = nil
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
  }
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    print(#function)

    progress = nil
  }

  private struct Progress {
    let range: Range<String.Index>
    let lastWord: String
    let remainingText: String
    let speechText: String
  }
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
    print(#function)

    guard let range = Range(characterRange, in: utterance.speechString) else {
      return
    }

    let lastWord = String(utterance.speechString[range])
    let remainingText = String(utterance.speechString.suffix(from: range.upperBound))
    progress = .init(
      range: range,
      lastWord: lastWord,
      remainingText: remainingText,
      speechText: utterance.speechString
    )
  }
}
