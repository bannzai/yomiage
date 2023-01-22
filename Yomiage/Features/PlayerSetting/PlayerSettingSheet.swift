import SwiftUI

struct PlayerSettingSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var player: Synthesizer

  var body: some View {
    MediumSheetLayout {
      Text("設定")
        .font(.headline)
    } content: {
      VStack(spacing: 0) {
        VStack(spacing: 20) {
          VStack(alignment: .leading, spacing: 8) {
            Text("音量").font(.system(.subheadline))
            Slider(value: $player.volume, in: Range.volume)
          }
          VStack(alignment: .leading, spacing: 8) {
            Text("読む早さ").font(.system(.subheadline))
            Slider(value: $player.rate, in: Range.rate)
          }
          VStack(alignment: .leading, spacing: 8) {
            Text("声の高さ").font(.system(.subheadline))
            Slider(value: $player.pitch, in: Range.pitch)
          }
        }
        VSpacer(20)
      }
      .padding(.horizontal, 20)
    }
  }

  enum Range {
    static let volume = ClosedRange<Float>(uncheckedBounds: (lower: 0, upper: 1))
    static let rate = ClosedRange<Float>(uncheckedBounds: (lower: 0, upper: 1))
    static var pitch = ClosedRange<Float>(uncheckedBounds: (lower: 0, upper: 2))
  }
}

