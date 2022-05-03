import Combine
import SwiftUI
import AVFoundation

final class Player: ObservableObject {
  @Published var volume = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerVolume)
  @Published var rate = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerRate)
  @Published var pitch = UserDefaults.standard.float(forKey: UserDefaultsKeys.playerPitch)

  let synthesizer = AVSpeechSynthesizer()
  var canceller: Set<AnyCancellable> = []

  init() {
    bind()
    setup()
  }
}

private extension Player {
  func bind() {
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
      self?.setup()
    }.store(in: &canceller)
  }

  func setup() {
    let utterance = AVSpeechUtterance()
    utterance.volume = volume
    utterance.rate = rate
    utterance.pitchMultiplier = pitch

    synthesizer.speak(utterance)
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

