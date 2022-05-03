import SwiftUI

struct PlayerSettingSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var player: Player

  var body: some View {
    VStack(spacing: 40) {
      Text("設定")
        .font(.headline)

      VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text("音量").font(.system(size: 16))
          Slider(value: $player.volume, in: Range.volume)
        }
        VStack(alignment: .leading, spacing: 8) {
          Text("読む早さ").font(.system(size: 16))
          Slider(value: $player.rate, in: Range.rate)
        }
        VStack(alignment: .leading, spacing: 8) {
          Text("声の高さ").font(.system(size: 16))
          Slider(value: $player.pitch, in: Range.pitch)
        }

        Spacer()
      }
      .padding(.horizontal, 20)
    }
    .padding(.top, 30)
  }

  enum Range {
    static let volume = ClosedRange<Float>(uncheckedBounds: (lower: 0, upper: 1))
    static let rate = ClosedRange<Float>(uncheckedBounds: (lower: 0, upper: 1))
    static var pitch = ClosedRange<Float>(uncheckedBounds: (lower: 0, upper: 2))
  }
}

