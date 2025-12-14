/// Firebase configuration options for AI Stock Summary app.
///
/// This file contains platform-specific Firebase configuration that must match
/// the Firebase Console settings. Values are derived from:
/// - iOS: GoogleService-Info.plist
/// - Android: google-services.json (or Firebase Console)
///
/// IMPORTANT: The appId must be in the format "1:PROJECT_NUMBER:PLATFORM:HEX_ID"
/// Do NOT use the projectId as the appId - this will cause initialization failures.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Web Firebase configuration.
  /// Note: Web requires a valid appId from Firebase Console.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCbnJWJg7btLbIYKPqzKdfvNmVSwx-Sikw',
    appId: '1:492701567937:web:913d40', // Placeholder - update from Firebase Console if web is used
    messagingSenderId: '492701567937',
    projectId: 'new-flutter-ai',
    authDomain: 'new-flutter-ai.firebaseapp.com',
    storageBucket: 'new-flutter-ai.firebasestorage.app',
  );

  /// Android Firebase configuration.
  /// Values match the Firebase Console Android app registration.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbnJWJg7btLbIYKPqzKdfvNmVSwx-Sikw',
    appId: '1:492701567937:android:322a5455316d850c913d40',
    messagingSenderId: '492701567937',
    projectId: 'new-flutter-ai',
    databaseURL: 'https://new-flutter-ai-default-rtdb.firebaseio.com',
    storageBucket: 'new-flutter-ai.firebasestorage.app',
  );

  /// iOS Firebase configuration.
  /// Values MUST match GoogleService-Info.plist exactly.
  /// GOOGLE_APP_ID in plist = appId here
  /// API_KEY in plist = apiKey here
  /// GCM_SENDER_ID in plist = messagingSenderId here
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDThrNGEd0_M0F0-wM6aVAFVXyNXPRmwd4',
    appId: '1:492701567937:ios:06a822562b244ae2913d40',
    messagingSenderId: '492701567937',
    projectId: 'new-flutter-ai',
    storageBucket: 'new-flutter-ai.firebasestorage.app',
    databaseURL: 'https://new-flutter-ai-default-rtdb.firebaseio.com',
    iosBundleId: 'com.marketmindai',
  );

  /// macOS Firebase configuration.
  /// Uses same values as iOS since they share the Apple ecosystem.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDThrNGEd0_M0F0-wM6aVAFVXyNXPRmwd4',
    appId: '1:492701567937:ios:06a822562b244ae2913d40',
    messagingSenderId: '492701567937',
    projectId: 'new-flutter-ai',
    storageBucket: 'new-flutter-ai.firebasestorage.app',
    databaseURL: 'https://new-flutter-ai-default-rtdb.firebaseio.com',
    iosBundleId: 'com.marketmindai',
  );

  /// Windows Firebase configuration.
  /// Note: Windows requires a valid appId from Firebase Console if used.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCbnJWJg7btLbIYKPqzKdfvNmVSwx-Sikw',
    appId: '1:492701567937:web:913d40', // Placeholder - update if Windows is used
    messagingSenderId: '492701567937',
    projectId: 'new-flutter-ai',
    storageBucket: 'new-flutter-ai.firebasestorage.app',
  );
}