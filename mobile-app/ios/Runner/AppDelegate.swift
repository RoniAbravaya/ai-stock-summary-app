import Flutter
import UIKit
import FirebaseCore

/// Ensures Firebase is configured at the earliest possible point in the app lifecycle.
/// This helper class uses a static initializer to configure Firebase before any
/// other code runs, including Flutter plugins that might access Firebase.
private class FirebaseInitializer {
  static let shared = FirebaseInitializer()
  
  private init() {
    // This runs when the class is first accessed (which happens at static init time)
    configureFirebase()
  }
  
  func ensureInitialized() {
    // No-op, just ensures the singleton is created and Firebase is configured
  }
  
  private func configureFirebase() {
    // Check if already configured
    if FirebaseApp.app() != nil {
      NSLog("ℹ️ [FirebaseInitializer] Firebase already configured")
      return
    }
    
    // Check if GoogleService-Info.plist exists
    guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
      NSLog("❌ [FirebaseInitializer] GoogleService-Info.plist NOT FOUND!")
      return
    }
    
    NSLog("🔥 [FirebaseInitializer] Configuring Firebase...")
    NSLog("   Plist path: \(plistPath)")
    
    // Configure Firebase
    FirebaseApp.configure()
    
    if let app = FirebaseApp.app() {
      NSLog("✅ [FirebaseInitializer] Firebase configured: project=\(app.options.projectID ?? "?")")
    } else {
      NSLog("❌ [FirebaseInitializer] Firebase.configure() failed!")
    }
  }
}

// Force Firebase initialization at app launch by accessing the singleton
// This happens during static initialization, before main() runs
private let _ = FirebaseInitializer.shared

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override init() {
    // Ensure Firebase is configured before calling super.init()
    FirebaseInitializer.shared.ensureInitialized()
    super.init()
  }
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Double-check Firebase is configured (should be done by now)
    FirebaseInitializer.shared.ensureInitialized()
    
    // Register Flutter plugins AFTER Firebase is configured
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
