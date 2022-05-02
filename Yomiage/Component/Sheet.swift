import SwiftUI

struct Sheet<Content>: UIViewControllerRepresentable where Content: View {
  @Binding var isPresented: Bool

  var onDismiss: (() -> Void)? = nil
  var detents: [UISheetPresentationController.Detent] = [.medium()]
  @ViewBuilder let content: Content

  func makeUIViewController(context: Context) -> some UIViewController {
    let hostingController = HostingController(rootView: content)
//    hostingController.onDisappear = {
//      isPresented = false
//      onDismiss?()
//    }
    return hostingController
  }
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    if let sheetController = uiViewController.sheetPresentationController {
      sheetController.detents = [.medium()]
      sheetController.prefersGrabberVisible = true
      sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
      sheetController.largestUndimmedDetentIdentifier = .medium
    }

    uiViewController.presentationController?.delegate = context.coordinator
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(isPresented: $isPresented, onDismiss: onDismiss)
  }

  class Coordinator: NSObject, UISheetPresentationControllerDelegate {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?

    init(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
      self._isPresented = isPresented
      self.onDismiss = onDismiss
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
      isPresented = false
      onDismiss?()
    }
  }
}


// Workaround Handle @Environment(\.dismiss)
private class HostingController<Content: View>: UIHostingController<Content> {
  var onDisappear: (() -> Void)!

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    onDisappear()
  }
}
