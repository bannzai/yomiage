import SwiftUI

struct UniversalErrorView: View {
  let error: Error
  let reload: () -> Void

  var body: some View {
    // TODO: Switch view for each error
    ReloadOnErrorButton(error: error, reload: reload)
  }
}

struct ReloadOnErrorButton: View {
  let error: Error
  let reload: () -> Void

  var body: some View {
    VStack {
      Text("問題が発生しました")
      Button("再読み込みをする", action: reload)
        .buttonStyle(.primary)
        .frame(maxWidth: .infinity)

      Text("詳細: \(error.localizedDescription)")
    }
  }
}
