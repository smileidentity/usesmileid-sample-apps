import UIKit
import UseSmileID

/// The one UIKit hook a SwiftUI app still needs: document capture rotates only if the host returns the SDK's mask.
final class UseSmileIDSampleAppDelegate: NSObject, UIApplicationDelegate {
  /// Portrait outside document capture and whatever the SDK locks to inside it; the plist alone cannot hold a rotation.
  func application(
    _: UIApplication,
    supportedInterfaceOrientationsFor _: UIWindow?
  ) -> UIInterfaceOrientationMask {
    UseSmileIDOrientationController.shared.mask
  }
}
