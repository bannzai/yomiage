import SwiftUI

struct AsyncButton<Label: View>: View {
  @State private var isLoading = false

  let action: () async -> Void
  @ViewBuilder let label: Label

  var body: some View {
    Button {
      Task { @MainActor in
        isLoading = true
        await action()
        isLoading = false
      }
    } label: {
      if isLoading {
        ProgressView()
      } else {
        label
      }
    }
  }
}

