import UIKit
import Flutter
import FBSDKCoreKit          // CocoaPods: FBSDKCoreKit 16+
import AppTrackingTransparency

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Facebook SDK başlat
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions)

    // ATT penceresi • iOS 14+
    ATTrackingManager.requestTrackingAuthorization { status in
        Settings.shared.isAdvertiserTrackingEnabled = (status == .authorized)
    }

    // Flutter plug-in’leri
    GeneratedPluginRegistrant.register(with: self)

    // App Install / Activate olayı
    AppEvents.shared.activateApp()

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions)
  }

  // (Opsiyonel ama bırakmak güvenli – Login/Share kullanırsan lazım)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return ApplicationDelegate.shared.application(app, open: url, options: options) ||
           super.application(app, open: url, options: options)
  }
}