import SwiftUI

// MARK: - Float
// NOTE: AppStorage does not support `Float`
extension UserDefaults {
  enum FloatKey: String {
    case synthesizerVolume
    case synthesizerRate
    case synthesizerPitch

    static private let prefix = "FloatKey"
    var key: String {
      "\(Self.prefix).\(rawValue)"
    }

    var defaultValue: Float {
      switch self {
      case .synthesizerVolume:
        return 0.5
      case .synthesizerRate:
        return 0.53
      case .synthesizerPitch:
        return 1.0
      }
    }
  }

  func set(_ value: Float, forKey key: FloatKey) {
    set(value, forKey: key.key)
  }

  func floatOrDefault(forKey key: FloatKey) -> Float {
    if dictionaryRepresentation().keys.contains(key.key) {
      return float(forKey: key.key)
    } else {
      return key.defaultValue
    }
  }
}
