/// Firebase initialization diagnostics and validation.
///
/// This service provides detailed diagnostic information when Firebase
/// initialization fails, helping developers quickly identify configuration
/// issues on both Android and iOS platforms.
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Diagnostic result for Firebase initialization.
class FirebaseDiagnosticResult {
  final bool success;
  final String? error;
  final String? platformDetails;
  final List<String> warnings;

  const FirebaseDiagnosticResult({
    required this.success,
    this.error,
    this.platformDetails,
    this.warnings = const [],
  });
}

/// Validates Firebase options for the current platform.
class FirebaseDiagnostics {
  /// Validates that the Firebase options appear correctly configured.
  /// Returns a list of validation warnings/errors.
  static List<String> validateOptions(FirebaseOptions options) {
    final warnings = <String>[];

    // Check appId format (should be 1:PROJECT_NUMBER:PLATFORM:HEX_ID)
    final appIdPattern = RegExp(r'^1:\d+:(android|ios|web):[a-f0-9]+$');
    if (!appIdPattern.hasMatch(options.appId)) {
      warnings.add(
        'Invalid appId format: "${options.appId}". '
        'Expected format: 1:PROJECT_NUMBER:PLATFORM:HEX_ID (e.g., 1:123456789:ios:abc123def456)',
      );
    }

    // Check apiKey format (should start with AIza)
    if (!options.apiKey.startsWith('AIza')) {
      warnings.add(
        'Suspicious apiKey format: "${options.apiKey}". '
        'Firebase API keys typically start with "AIza".',
      );
    }

    // Check messagingSenderId (should be numeric)
    if (!RegExp(r'^\d+$').hasMatch(options.messagingSenderId)) {
      warnings.add(
        'Invalid messagingSenderId: "${options.messagingSenderId}". '
        'Should be a numeric project number.',
      );
    }

    // Check projectId (should not contain spaces or special characters)
    if (!RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(options.projectId)) {
      warnings.add(
        'Suspicious projectId: "${options.projectId}". '
        'Should be lowercase alphanumeric with hyphens.',
      );
    }

    return warnings;
  }

  /// Returns platform-specific diagnostic information.
  static String getPlatformDiagnostics() {
    final buffer = StringBuffer();
    buffer.writeln('=== Firebase Diagnostics ===');
    buffer.writeln('Platform: ${defaultTargetPlatform.name}');
    buffer.writeln('Is Web: $kIsWeb');
    buffer.writeln('Debug Mode: $kDebugMode');

    if (!kIsWeb) {
      try {
        final options = DefaultFirebaseOptions.currentPlatform;
        buffer.writeln('Project ID: ${options.projectId}');
        buffer.writeln('App ID: ${options.appId}');
        buffer.writeln('Messaging Sender ID: ${options.messagingSenderId}');

        final validationWarnings = validateOptions(options);
        if (validationWarnings.isNotEmpty) {
          buffer.writeln('\n⚠️ Configuration Warnings:');
          for (final warning in validationWarnings) {
            buffer.writeln('  - $warning');
          }
        } else {
          buffer.writeln('\n✅ Configuration appears valid');
        }
      } catch (e) {
        buffer.writeln('❌ Failed to get platform options: $e');
      }
    }

    return buffer.toString();
  }

  /// Logs detailed diagnostic information for Firebase initialization failure.
  static void logInitializationError(Object error, StackTrace? stackTrace) {
    final errorStr = error.toString().toLowerCase();

    print('╔══════════════════════════════════════════════════════════════════╗');
    print('║            FIREBASE INITIALIZATION FAILURE                       ║');
    print('╚══════════════════════════════════════════════════════════════════╝');
    print('');
    print('Error: $error');
    print('');
    print(getPlatformDiagnostics());
    print('');

    // Platform-specific guidance
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      _logIOSDiagnostics(errorStr);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      _logAndroidDiagnostics(errorStr);
    }

    // Common issues
    if (errorStr.contains('not configured') ||
        errorStr.contains('no app has been configured')) {
      print('📋 COMMON CAUSE: Firebase app not configured before use.');
      print('   - Ensure Firebase.initializeApp() is called before any Firebase service');
      print('   - Check that the correct platform options are being used');
      print('');
    }

    if (errorStr.contains('duplicate') || errorStr.contains('already exists')) {
      print('📋 COMMON CAUSE: Firebase initialized multiple times.');
      print('   - Check that Firebase.initializeApp() is not called twice');
      print('   - AppDelegate.swift should only call FirebaseApp.configure() once');
      print('');
    }

    if (stackTrace != null && kDebugMode) {
      print('Stack trace:');
      print(stackTrace);
    }

    print('════════════════════════════════════════════════════════════════════');
  }

  static void _logIOSDiagnostics(String errorStr) {
    print('📱 iOS/macOS Specific Checks:');
    print('   1. Verify GoogleService-Info.plist exists at:');
    print('      ios/Runner/GoogleService-Info.plist');
    print('');
    print('   2. Check plist is in Xcode target membership:');
    print('      - Open ios/Runner.xcworkspace in Xcode');
    print('      - Select GoogleService-Info.plist');
    print('      - Ensure "Runner" is checked in Target Membership');
    print('');
    print('   3. Verify plist is in "Copy Bundle Resources":');
    print('      - Select Runner target > Build Phases');
    print('      - Check "Copy Bundle Resources" includes the plist');
    print('');
    print('   4. Check firebase_options.dart iOS values match plist:');
    print('      - appId should match GOOGLE_APP_ID in plist');
    print('      - apiKey should match API_KEY in plist');
    print('      - iosBundleId should match BUNDLE_ID in plist');
    print('');
    print('   5. Check AppDelegate.swift:');
    print('      - Should import FirebaseCore');
    print('      - Should call FirebaseApp.configure() once');
    print('');
  }

  static void _logAndroidDiagnostics(String errorStr) {
    print('🤖 Android Specific Checks:');
    print('   1. If using google-services.json:');
    print('      - Verify file exists at android/app/google-services.json');
    print('      - Check applicationId matches package_name in JSON');
    print('');
    print('   2. If using firebase_options.dart only:');
    print('      - Check android appId format: 1:PROJECT_NUM:android:HEX_ID');
    print('      - Verify values match Firebase Console');
    print('');
    print('   3. Check android/app/build.gradle.kts:');
    print('      - Firebase dependencies are included');
    print('      - google-services plugin is applied (if using JSON)');
    print('');
  }

  /// Check if Firebase is already initialized.
  static bool get isInitialized => Firebase.apps.isNotEmpty;
}
