import UIKit
import Flutter
import WebViewFlutterPlugin

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let controller = window?.rootViewController as! FlutterViewController
    let webViewFlutterPlugin = FLTWebViewFlutterPlugin.init(controller)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
