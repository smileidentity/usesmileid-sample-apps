import SwiftUI

/// Reports when a pushed level's transition has ended. SwiftUI's `onAppear` fires inside that
/// transition, and UIKit drops a push made before it ends, so the router lands the next level here.
struct UseSmileIDSampleTransitionEnd: UIViewControllerRepresentable {
  let action: () -> Void

  func makeUIViewController(context _: Context) -> Controller {
    Controller(action: action)
  }

  func updateUIViewController(_ controller: Controller, context _: Context) {
    controller.action = action
  }

  final class Controller: UIViewController {
    var action: () -> Void

    init(action: @escaping () -> Void) {
      self.action = action
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
      nil
    }

    override func viewDidLoad() {
      super.viewDidLoad()
      view.isUserInteractionEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      action()
    }
  }
}
