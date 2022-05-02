import SwiftUI

struct Sheet<Content>: UIViewRepresentable where Content: View {
  let detents: [UISheetPresentationController.Detent]
  @ViewBuilder let content: Content

  func makeUIView(context: Context) -> UIView {
    .init()
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    let hostingController = UIHostingController(rootView: content)
    if let sheetController = hostingController.sheetPresentationController {
      sheetController.detents = detents
      sheetController.prefersGrabberVisible = true
      sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
      sheetController.largestUndimmedDetentIdentifier = .medium
    }

    uiView.window?.rootViewController?.present(hostingController, animated: true)
  }

  func makeCoordinator() -> Void {
    ()
  }
}
