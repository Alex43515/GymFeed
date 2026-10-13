import UIKit

import Flutter
import GoogleMaps
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAhiNjvBpWvH1VVuoRGU5J3WnjVPFIzkE4")
    GeneratedPluginRegistrant.register(with: self)
    if let healthRegistrar = registrar(forPlugin: "GymFeedHealthAvailability") {
      let channel = FlutterMethodChannel(name: "gymfeed/health_settings", binaryMessenger: healthRegistrar.messenger())
      channel.setMethodCallHandler { call, result in
        if call.method == "isAvailable" {
          result(HKHealthStore.isHealthDataAvailable())
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
