import SwiftUI

struct AsyncButton<Label: View>: View {
  typealias AsyncAction = () async -> Void

  let action: AsyncAction
  @ViewBuilder let label: Label

  init(action: @escaping AsyncAction, label: () -> Label) {
    self.action = action
    self.label = label()
  }
  init(_ title: String, action: @escaping AsyncAction) where Label == Text {
    self.label = Text(title)
    self.action = action
  }

  @State private var isExecuting = false

  var body: some View {
    Button {
      Task { @MainActor in
        isExecuting = true
        await action()
        isExecuting = false
      }
    } label: {
      if isExecuting {
        ProgressView()
      } else {
        label
      }
    }
  }
}

