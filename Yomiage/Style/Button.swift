import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 16, weight: .semibold))
      .padding(.vertical, 12)
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(isEnabled ? Color.primary : Color(.systemGray3))
      )
      .opacity(configuration.isPressed ? 0.7 : 1.0)
      .foregroundColor(.white)
  }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
  static var primary: PrimaryButtonStyle { .init() }
}
