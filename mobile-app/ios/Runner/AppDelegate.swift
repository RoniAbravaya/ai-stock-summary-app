import Flutter
import UIKit
import FirebaseCore

/// AppDelegate for the Flutter app.
/// 
/// Note: Firebase is configured in FirebaseLoader.m using +load method,
/// which runs before main() and before this AppDelegate is instantiated.
/// This ensures Firebase is ready before any Flutter plugins try to access it.
@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase should already be configured by FirebaseLoader.m's +load method.
    // Log the status for debugging.
    if let app = FirebaseApp.app() {
      NSLog("✅ [AppDelegate] Firebase is configured: \(app.options.projectID ?? "?")")
    } else {
      // This shouldn't happen if FirebaseLoader.m is working correctly
      NSLog("⚠️ [AppDelegate] Firebase not configured, attempting to configure now...")
      FirebaseApp.configure()
    }
    
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
