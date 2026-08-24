import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var privacyBlurView: UIVisualEffectView?

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    guard let window = self.window else { return }
    if privacyBlurView == nil {
      let blurEffect = UIBlurEffect(style: .dark)
      let blurView = UIVisualEffectView(effect: blurEffect)
      blurView.frame = window.bounds
      blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      blurView.tag = 9999
      window.addSubview(blurView)
      privacyBlurView = blurView
    }
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    privacyBlurView?.removeFromSuperview()
    privacyBlurView = nil
  }
}
