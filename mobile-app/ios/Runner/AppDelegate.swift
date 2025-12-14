import UIKit
import Flutter
import FirebaseCore

/// AppDelegate for the Flutter app.
///
/// Firebase is configured here in didFinishLaunchingWithOptions, BEFORE
/// registering Flutter plugins. This ensures Firebase is ready before
/// any plugin tries to use Firebase services.
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Firebase FIRST, before any plugins are registered
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            NSLog("✅ [AppDelegate] Firebase configured")
        } else {
            NSLog("ℹ️ [AppDelegate] Firebase already configured")
        }
        
        // Register Flutter plugins AFTER Firebase is configured
        GeneratedPluginRegistrant.register(with: self)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
