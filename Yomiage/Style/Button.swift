import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  @Environment(\.buttonPadding) var buttonPadding
  @Environment(\.isEnabled) var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(buttonPadding)
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
  static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

struct ButtonPaddingEnvironmentKey: EnvironmentKey {
  static var defaultValue: EdgeInsets = EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
}
extension EnvironmentValues {
  var buttonPadding: EdgeInsets {
    get { self[ButtonPaddingEnvironmentKey.self] }
    set { self[ButtonPaddingEnvironmentKey.self] = newValue }
  }
}
