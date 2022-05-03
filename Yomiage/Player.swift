import Combine
import SwiftUI
import AVFoundation

final class Player: NSObject, ObservableObject {
  @Published var volume = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerVolume)
  @Published var rate = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerRate)
  @Published var pitch = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerPitch)

  private var speakingText: String?
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

    speakingText = text

    synthesizer.speak(utterance)
  }
}

private extension Player {
  func reset() {
//    if synthesizer.isSpeaking {
//      synthesizer.stopSpeaking(at: <#T##AVSpeechBoundary#>)
//    }
//    speak(text: String)
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
  private struct Progress {
    var range: Range<String.Index>
    var lastWord: String
    var speechString: String
  }
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
    guard let range = Range(characterRange, in: utterance.speechString) else {
      return
    }

    let lastWord = utterance.speechString[range]
    progress = .init(range: range, lastWord: String(lastWord), speechString: utterance.speechString)
  }
}
