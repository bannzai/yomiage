import Combine
import SwiftUI
import AVFoundation

final class Player: NSObject, ObservableObject {
  @Published var volume = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerVolume)
  @Published var rate = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerRate)
  @Published var pitch = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerPitch)

  private var progress: Progress?

  let synthesizer = AVSpeechSynthesizer()
  var canceller: Set<AnyCancellable> = []

  override init() {
    super.init()

    $volume.sink { volume in
      UserDefaults.standard.set(volume, forKey: UserDefaultsKeys.playerVolume)
    }.store(in: &canceller)
    $rate.sink { rate in
      UserDefaults.standard.set(rate, forKey: UserDefaultsKeys.playerRate)
    }.store(in: &canceller)
    $pitch.sink { pitch in
      UserDefaults.standard.set(pitch, forKey: UserDefaultsKeys.playerPitch)
    }.store(in: &canceller)

    objectWillChange.sink { [weak self] in
      self?.reset()
    }.store(in: &canceller)

    synthesizer.delegate = self
  }

  func speak(text: String) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.volume = volume
    utterance.rate = rate
    utterance.pitchMultiplier = pitch

    synthesizer.speak(utterance)
  }
}

private extension Player {
  func reset() {
    // NOTE: Avoid flush value after synthesizer.stopSpeaking -> speechSynthesizer(:didCancel).
    let _remainingText = progress?.remainingText

    // NOTE: call synthesizer.speak is not speaking and is broken synthesizer when synthesizer.isSpeaking
    guard synthesizer.isSpeaking else {
      return
    }
    synthesizer.stopSpeaking(at: .word)

    if let remainingText = _remainingText {
      speak(text: remainingText)
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
