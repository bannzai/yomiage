import SwiftUI

struct StreamView<Data, Loading: View, Error: View, Content: View>: View {
  @State private var isFirstTask = true
  @State private var isLoading = true
  @State private var data: Data?
  @State private var error: Swift.Error?

  typealias ReloadStreamHandler = () async -> Void

  let stream: AsyncThrowingStream<Data, Swift.Error>
  @ViewBuilder let content: (Data, @escaping ReloadStreamHandler) -> Content
  @ViewBuilder let errorContent: (_ error: Swift.Error, _ reload: @escaping ReloadStreamHandler) -> Error
  @ViewBuilder let loading: () -> Loading

  var body: some View {
    Group {
      if isLoading {
        loading()
      } else if let data = data {
        content(data, {
          Task { @MainActor in
            await listenStream()
          }
        })
      } else if let error = error {
        errorContent(error, {
          Task { @MainActor in
            await listenStream()
          }
        })
      }
    }.task {
      if isFirstTask {
        await listenStream()
        isFirstTask = false
      }
    }
  }

  private func listenStream() async {
    do {
      for try await data in stream {
        self.data = data

        if isLoading {
          isLoading = false
        }
      }
    } catch {
      self.error = error
    }
  }
}
