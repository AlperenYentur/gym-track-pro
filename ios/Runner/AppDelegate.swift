import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  lazy var flutterEngine = FlutterEngine(name: "main engine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Run the engine explicitly, before the root view controller is created, so
    // FlutterViewController.viewDidLoad never races the implicit-engine attach path.
    // That race (self.engine.platformTaskRunner still null when
    // createTouchRateCorrectionVSyncClientIfNeeded runs) is a known Flutter engine
    // bug on ProMotion (>60Hz) displays: https://github.com/flutter/flutter/issues/183900
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    let appWindow = UIWindow(frame: UIScreen.main.bounds)
    appWindow.rootViewController = flutterViewController
    appWindow.makeKeyAndVisible()
    window = appWindow

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
