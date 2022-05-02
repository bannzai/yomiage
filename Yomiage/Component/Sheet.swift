import SwiftUI

struct Sheet<Content>: UIViewRepresentable where Content: View {
  @Binding var isPresented: Bool

  var onDismiss: (() -> Void)? = nil
  let detents: [UISheetPresentationController.Detent]
  @ViewBuilder let content: Content

  func makeUIView(context: Context) -> UIView {
    .init()
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    let viewControllerToPresent = UIViewController()
    let hostingController = HostingController(rootView: content)

    hostingController.onDisappear = {
      isPresented = false
      onDismiss?()
    }

    viewControllerToPresent.addChild(hostingController)
    viewControllerToPresent.view.addSubview(hostingController.view)

    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.leftAnchor.constraint(equalTo: viewControllerToPresent.view.leftAnchor),
      hostingController.view.topAnchor.constraint(equalTo: viewControllerToPresent.view.topAnchor),
      hostingController.view.rightAnchor.constraint(equalTo: viewControllerToPresent.view.rightAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: viewControllerToPresent.view.bottomAnchor),
    ])
    hostingController.didMove(toParent: viewControllerToPresent)

    if let sheetController = viewControllerToPresent.sheetPresentationController {
      sheetController.detents = detents
      sheetController.prefersGrabberVisible = true
      sheetController.prefersScrollingExpandsWhenScrolledToEdge = false
      sheetController.largestUndimmedDetentIdentifier = .medium
    }

    viewControllerToPresent.presentationController?.delegate = context.coordinator

    if isPresented {
      uiView.window?.rootViewController?.present(viewControllerToPresent, animated: true)
    } else {
      uiView.window?.rootViewController?.dismiss(animated: true)
    }
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
