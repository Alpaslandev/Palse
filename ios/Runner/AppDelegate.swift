import UIKit
import Flutter
import FBSDKCoreKit
import AppTrackingTransparency

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var attAsked = false     // ATT yalnızca bir kez tetiklensin

  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 1) Facebook SDK init (gereken “initialize” adımı budur)
    ApplicationDelegate.shared.application(
        application,
        didFinishLaunchingWithOptions: launchOptions)

    // 2) Flutter plug-in’leri
    GeneratedPluginRegistrant.register(with: self)

    // 3) İlk App Activate (IDFA'sız da olsa install sayımı yapar)
    AppEvents.shared.activateApp()

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions)
  }

  /// ATT popup’ını yalnızca uygulama aktif olduğunda göster.
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)

    guard #available(iOS 14, *), attAsked == false else { return }
    attAsked = true

    let current = ATTrackingManager.trackingAuthorizationStatus
    if current == .notDetermined {
      ATTrackingManager.requestTrackingAuthorization { status in
        print("📢 ATT sonucu:", status.rawValue)   // 0‒3

        // ⚠️ FBSDK v17+: iOS 17+’de bu setter KULLANILMAZ.
        //      iOS 14–16'da hâlâ geçerli → koşullu çağır.
        if #available(iOS 17, *) {
          // hiçbir şey yapma, SDK kendi okuyor
        } else {
          Settings.shared.isAdvertiserTrackingEnabled = (status == .authorized)
        }
          AppEvents.shared.activateApp()

        // İzin çıktıktan sonra event’leri flush etmek istersen:
          AppEvents.shared.flush()
      }
    }
  }
}
