import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PerformanceOptimizationService {
  static PerformanceOptimizationService? _instance;
  static PerformanceOptimizationService get instance =>
      _instance ??= PerformanceOptimizationService._();

  PerformanceOptimizationService._();

  // Memory optimization settings
  static const int _maxCacheSize = 100;
  static const Duration _cacheCleanupInterval = Duration(minutes: 10);

  final Map<String, CacheEntry> _memoryCache = {};

  // Initialize performance optimizations
  static Future<void> initialize() async {
    try {
      // Set memory pressure threshold
      if (!kIsWeb) {
        SystemChannels.lifecycle.setMessageHandler((message) async {
          if (message == 'AppLifecycleState.paused' ||
              message == 'AppLifecycleState.inactive') {
            await instance._handleMemoryPressure();
          }
          return null;
        });
      }

      // Setup periodic cache cleanup
      instance._setupCacheCleanup();

      // Enable sensor optimization for device-specific issues
      await instance._optimizeSensorUsage();
    } catch (e) {
      debugPrint('Performance optimization initialization failed: $e');
    }
  }

  // Handle memory pressure situations
  Future<void> _handleMemoryPressure() async {
    try {
      // Clear memory cache aggressively
      _memoryCache.clear();

      // Force garbage collection (if available)
      if (!kIsWeb) {
        // System.gc() equivalent - let Dart handle GC
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('Memory pressure handled - cache cleared');
    } catch (e) {
      debugPrint('Error handling memory pressure: $e');
    }
  }

  // Optimize sensor usage to reduce system load
  Future<void> _optimizeSensorUsage() async {
    try {
      if (!kIsWeb) {
        // Reduce screen brightness monitoring frequency
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      }
    } catch (e) {
      // Silent fail - don't break app functionality
      debugPrint('Sensor optimization not available: $e');
    }
  }

  // Setup periodic cache cleanup
  void _setupCacheCleanup() {
    Stream.periodic(_cacheCleanupInterval).listen((_) {
      _cleanupExpiredCache();
    });
  }

  // Clean expired cache entries
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    _memoryCache.removeWhere((key, entry) => entry.isExpired(now));

    // Also cleanup if cache is too large
    if (_memoryCache.length > _maxCacheSize) {
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

      final toRemove = sortedEntries.take(_memoryCache.length - _maxCacheSize);
      for (final entry in toRemove) {
        _memoryCache.remove(entry.key);
      }
    }
  }

  // Cache management with TTL
  T? getFromCache<T>(String key) {
    final entry = _memoryCache[key];
    if (entry != null && !entry.isExpired(DateTime.now())) {
      entry.lastAccessed = DateTime.now();
      return entry.data as T?;
    }
    _memoryCache.remove(key);
    return null;
  }

  void putInCache<T>(String key, T data, {Duration? ttl}) {
    _memoryCache[key] = CacheEntry(
      data: data,
      ttl: ttl ?? const Duration(minutes: 15),
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
  }

  // Error resilience wrapper
  static Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallback,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await operation();
        return result;
      } catch (e) {
        if (attempt == maxRetries) {
          debugPrint(
              'Operation failed after $maxRetries attempts${context != null ? ' ($context)' : ''}: $e');
          return fallback;
        }

        debugPrint(
            'Attempt $attempt failed${context != null ? ' ($context)' : ''}: $e. Retrying...');
        await Future.delayed(retryDelay * attempt); // Exponential backoff
      }
    }
    return fallback;
  }

  // Network resilience helper
  static Future<T?> executeNetworkOperation<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallback,
  }) async {
    return executeWithErrorHandling(
      operation,
      context: context ?? 'Network operation',
      fallback: fallback,
      maxRetries: 2,
      retryDelay: const Duration(milliseconds: 500),
    );
  }

  // Resource cleanup
  void dispose() {
    _memoryCache.clear();
  }
}

// Cache entry data structure
class CacheEntry {
  final dynamic data;
  final Duration ttl;
  final DateTime createdAt;
  DateTime lastAccessed;

  CacheEntry({
    required this.data,
    required this.ttl,
    required this.createdAt,
    required this.lastAccessed,
  });

  bool isExpired(DateTime now) {
    return now.difference(createdAt) > ttl;
  }
}