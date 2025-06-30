import UIKit
import Flutter
import FBSDKCoreKit
import AppTrackingTransparency
import AdSupport

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Facebook SDK başlatılıyor
    ApplicationDelegate.shared.application(
        application,
        didFinishLaunchingWithOptions: launchOptions)

    // ATT isteği — iOS 14+
    if #available(iOS 14, *) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ATTrackingManager.requestTrackingAuthorization { status in
                print("📢 ATT durumu: \(status.rawValue)") // 0:notDetermined, 1:restricted, 2:denied, 3:authorized
                // FB v17+ zaten status'u otomatik alıyor
            }
        }
    }

    GeneratedPluginRegistrant.register(with: self)
    AppEvents.shared.activateApp() // App install / open event

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}