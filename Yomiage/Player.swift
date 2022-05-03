import SwiftUI

final class Player: ObservableObject {
  struct DefaultValues {
    let key: String
    let value: Double

    static var volume = DefaultValues(key: UserDefaultsKeys.playerVolume, value: 0.5)
    static var rate = DefaultValues(key: UserDefaultsKeys.playerRate, value: 0.53)
    static var pitch = DefaultValues(key: UserDefaultsKeys.playerPitch, value: 1.0)

    static func setup() {
      [volume, rate, pitch].forEach {
        if !UserDefaults.standard.dictionaryRepresentation().keys.contains($0.key) {
          UserDefaults.standard.set($0.value, forKey: $0.key)
        }
      }
    }
  }

    // 0.0 ~ 1.0
  @Published var volume = UserDefaults.standard.double(forKey: UserDefaultsKeys.playerVolume)
    // 0.0 ~ 1.0
  @Published var rate = UserDefaults.standard.double(forKey: UserDefaultsKeys.playerRate)
    // 0.0 ~ 2.0
  @Published var pitch = UserDefaults.standard.double(forKey: UserDefaultsKeys.playerPitch)
}

