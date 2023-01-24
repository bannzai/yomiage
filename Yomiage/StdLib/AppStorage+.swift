import SwiftUI

// MARK: - Double
// NOTE: AppStorage does not support `Float`
extension UserDefaults {
  enum DoubleKey: String {
    case synthesizerVolume
    case synthesizerRate
    case synthesizerPitch

    case playerRate

    static private let prefix = "DoubleKey"
    var key: String {
      "\(Self.prefix).\(rawValue)"
    }

    var defaultValue: Double {
      switch self {
      case .synthesizerVolume:
        return 0.5
      case .synthesizerRate:
        return 0.53
      case .synthesizerPitch:
        return 1.0
      case .playerRate:
        return 1
      }
    }
  }

  func set(_ value: Double, forKey key: DoubleKey) {
    set(value, forKey: key.key)
  }

  func doubleOrDefault(forKey key: DoubleKey) -> Double {
    if dictionaryRepresentation().keys.contains(key.key) {
      return double(forKey: key.key)
    } else {
      return key.defaultValue
    }
  }
}


extension AppStorage {
  typealias DoubleKey = UserDefaults.DoubleKey

  init(_ key: DoubleKey, store: UserDefaults? = nil) where Value == Double {
    self.init(wrappedValue: key.defaultValue, key.key, store: store)
  }
}
