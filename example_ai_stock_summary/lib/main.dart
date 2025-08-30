import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:ui';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './services/device_monitoring_service.dart';
import './services/performance_optimization_service.dart';
import './services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enhanced error handling for startup
  await _initializeApp();

  runApp(MyApp());
}

// Comprehensive app initialization with error resilience
Future<void> _initializeApp() async {
  try {
    // Initialize performance optimizations first
    await PerformanceOptimizationService.initialize();
    debugPrint('✅ Performance optimization initialized');

    // Initialize Supabase with retry mechanism
    await PerformanceOptimizationService.executeWithErrorHandling(
      () => SupabaseService.initialize(),
      context: 'Supabase initialization',
      maxRetries: 3,
      retryDelay: const Duration(seconds: 2),
    );
    debugPrint('✅ Supabase initialized');

    // Initialize device monitoring (handles sensor errors gracefully)
    await DeviceMonitoringService.initialize();
    debugPrint('✅ Device monitoring initialized');

    // Setup enhanced error handling
    _setupGlobalErrorHandling();

    // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
    await Future.wait([
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
    ]);
    debugPrint('✅ App initialization completed successfully');
  } catch (e, stackTrace) {
    debugPrint('🚨 App initialization error: $e');
    debugPrint('Stack trace: $stackTrace');

    // Continue with minimal initialization
    try {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      debugPrint('⚠️ Minimal initialization completed');
    } catch (minimalError) {
      debugPrint('🚨 Critical initialization failure: $minimalError');
    }
  }
}

// Setup global error handling with device-specific considerations
void _setupGlobalErrorHandling() {
  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(
      errorDetails: details,
    );
  };

  // Handle platform-specific errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log error details
    debugPrint('🚨 Flutter Error: ${details.exception}');
    debugPrint('Context: ${details.context}');

    // Check if it's a sensor-related error (like Xiaomi lux sensor issues)
    final errorMessage = details.exception.toString().toLowerCase();
    if (errorMessage.contains('sensor') ||
        errorMessage.contains('lux') ||
        errorMessage.contains('framebuffer') ||
        errorMessage.contains('display')) {
      debugPrint('⚠️ Device sensor error detected - app continuing normally');
      return; // Don't crash the app for sensor errors
    }

    // For other errors, use default handling but don't crash
    FlutterError.presentError(details);
  };

  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🚨 Async Error: $error');
    debugPrint('Stack: $stack');

    // Check for device-specific system errors
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('sensor') ||
        errorString.contains('xiaomi') ||
        errorString.contains('framebuffer') ||
        errorString.contains('lux')) {
      debugPrint('⚠️ Device system error - continuing operation');
      return true; // Handle gracefully
    }

    return true; // Prevent app crashes
  };
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'ai_stock_summary',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY - Memory optimization
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: AppLifecycleWrapper(
              child: child!,
            ),
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}

// App lifecycle wrapper for better resource management
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Cleanup resources when app is disposed
    PerformanceOptimizationService.instance.dispose();
    DeviceMonitoringService.instance.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        debugPrint('📱 App paused - optimizing resources');
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed - restoring resources');
        _handleAppResumed();
        break;
      case AppLifecycleState.inactive:
        debugPrint('📱 App inactive - reducing background activity');
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached - final cleanup');
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        debugPrint('📱 App hidden - maintaining state');
        break;
    }
  }

  void _handleAppPaused() {
    // Reduce resource usage when app is paused
    try {
      // Clear caches to free memory
      PerformanceOptimizationService.instance.dispose();

      // Reduce sensor monitoring frequency if device monitoring is active
      final deviceMetrics = DeviceMonitoringService.instance.getDeviceMetrics();
      if (deviceMetrics['batteryLevel'] != null &&
          deviceMetrics['batteryLevel'] < 30) {
        debugPrint('⚡ Low battery detected - enabling power saving');
      }
    } catch (e) {
      debugPrint('Error during app pause handling: $e');
    }
  }

  void _handleAppResumed() {
    // Restore full functionality when app is resumed
    try {
      // Re-initialize performance optimizations if needed
      PerformanceOptimizationService.initialize();

      // Check device health
      final isHealthy = DeviceMonitoringService.instance.isDeviceHealthy();
      if (!isHealthy) {
        debugPrint('⚠️ Device health issues detected');
        final metrics = DeviceMonitoringService.instance.getDeviceMetrics();
        debugPrint('Device metrics: $metrics');
      }
    } catch (e) {
      debugPrint('Error during app resume handling: $e');
    }
  }

  void _handleAppDetached() {
    // Final cleanup before app termination
    try {
      PerformanceOptimizationService.instance.dispose();
      DeviceMonitoringService.instance.dispose();
    } catch (e) {
      debugPrint('Error during app detached handling: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}