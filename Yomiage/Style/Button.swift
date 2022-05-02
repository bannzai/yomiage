import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label.padding(.horizontal, 20)
      .padding(.vertical, 16)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(isEnabled ? Color.primary : Color(.systemGray3))
      )
      .opacity(configuration.isPressed ? 0.7 : 1.0)
  }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
  static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
