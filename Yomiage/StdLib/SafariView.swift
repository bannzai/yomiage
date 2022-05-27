import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
  var url: URL

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let safariViewController = SFSafariViewController(url: url, configuration: .init())
    return safariViewController
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
  }
}
