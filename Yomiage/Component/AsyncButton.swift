import SwiftUI

struct AsyncButton<Label: View, Progress: View>: View {
  @State private var isLoading = false

  let action: () async -> Void
  @ViewBuilder let label: Label
  @ViewBuilder let progress: Progress

  var body: some View {
    Button {
      Task { @MainActor in
        isLoading = true
        await action()
        isLoading = false
      }
    } label: {
      if isLoading {
        progress
      } else {
        label
      }
    }
  }
}

