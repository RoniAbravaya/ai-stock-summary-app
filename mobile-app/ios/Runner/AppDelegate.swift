import Flutter
import UIKit
import FirebaseCore

/// AppDelegate for the Flutter app.
/// 
/// Firebase configuration is handled by FirebaseLoader.m's +load method which runs
/// before main(). This AppDelegate serves as a fallback if that fails.
@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Check Firebase status - it should already be configured by FirebaseLoader.m
    if FirebaseApp.app() != nil {
      NSLog("✅ [AppDelegate] Firebase already configured")
    } else {
      // Fallback: configure Firebase here if +load didn't work
      NSLog("⚠️ [AppDelegate] Firebase not configured, configuring now...")
      FirebaseApp.configure()
      if FirebaseApp.app() != nil {
        NSLog("✅ [AppDelegate] Firebase configured successfully")
      } else {
        NSLog("❌ [AppDelegate] Firebase configuration failed")
      }
    }
    
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
