import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  /// A cold-start link becomes the engine's initial route, as Flutter's Android embedding makes it, since the shell reads its launch arguments there.
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let url = connectionOptions.urlContexts.first?.url,
       let controller = window?.rootViewController as? FlutterViewController {
      controller.engine.navigationChannel.invokeMethod("setInitialRoute", arguments: url.absoluteString)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
