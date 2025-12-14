import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  // Configure Firebase as early as possible - in init() before any other code runs
  override init() {
    super.init()
    
    // This runs before didFinishLaunchingWithOptions and before plugins load
    Self.configureFirebaseOnce()
  }
  
  // Static method to ensure Firebase is configured exactly once
  private static var firebaseConfigured = false
  
  private static func configureFirebaseOnce() {
    guard !firebaseConfigured else {
      NSLog("ℹ️ Firebase already configured (skipping)")
      return
    }
    
    NSLog("🔥 Configuring Firebase in AppDelegate.init()...")
    
    // Check if GoogleService-Info.plist exists in bundle
    if let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
      NSLog("✅ GoogleService-Info.plist found at: \(plistPath)")
      
      // Verify we can read the plist
      if let plistData = NSDictionary(contentsOfFile: plistPath) {
        if let projectId = plistData["PROJECT_ID"] as? String {
          NSLog("   Project ID: \(projectId)")
        }
        if let appId = plistData["GOOGLE_APP_ID"] as? String {
          NSLog("   App ID: \(appId)")
        }
        if let bundleId = plistData["BUNDLE_ID"] as? String,
           let appBundleId = Bundle.main.bundleIdentifier {
          if bundleId != appBundleId {
            NSLog("⚠️ Bundle ID mismatch! Plist: \(bundleId), App: \(appBundleId)")
          }
        }
      }
    } else {
      NSLog("❌ GoogleService-Info.plist NOT FOUND in bundle!")
      return
    }
    
    // Configure Firebase
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      firebaseConfigured = true
      
      if let app = FirebaseApp.app() {
        NSLog("✅ Firebase configured successfully: \(app.options.projectID ?? "unknown")")
      } else {
        NSLog("❌ Firebase.configure() called but FirebaseApp.app() is nil!")
      }
    } else {
      firebaseConfigured = true
      NSLog("ℹ️ Firebase was already configured by another component")
    }
  }
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Ensure Firebase is configured (should already be done in init, but just in case)
    Self.configureFirebaseOnce()
    
    // Register Flutter plugins AFTER Firebase is configured
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
