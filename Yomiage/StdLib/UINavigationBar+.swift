import UIKit

extension UINavigationController {
  open override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }
}
