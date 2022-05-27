import SwiftUI

struct NavigationLinkButton<Destination: View, Label: View>: View {
  @ViewBuilder let destination: Destination
  @ViewBuilder let label: () -> Label
  var tapped: () -> Void = { }

  @State private var isActive = false

  var body: some View {
    Button {
      tapped()

      isActive = true
    } label: {
      ZStack {
        NavigationLink(isActive: $isActive, destination: { destination }) {
          EmptyView()
        }
        .opacity(0)

        label()
      }
    }
  }
}

struct NavigationLinkLayout<Leading: View>: View {
  @ViewBuilder let leading: Leading

  var body: some View {
    HStack {
      leading

      Spacer()

      Image(systemName: "chevron.right")
        .font(.system(.body))
        .foregroundColor(.systemGray2)
    }
    .frame(maxWidth: .infinity)
  }
}
