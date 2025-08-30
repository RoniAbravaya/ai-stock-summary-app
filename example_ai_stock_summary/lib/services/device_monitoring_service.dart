import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';

class DeviceMonitoringService {
  static DeviceMonitoringService? _instance;
  static DeviceMonitoringService get instance =>
      _instance ??= DeviceMonitoringService._();

  DeviceMonitoringService._();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<BatteryState>? _batterySubscription;

  bool _isMonitoring = false;
  final Battery _battery = Battery();

  // Sensor thresholds for detecting device stress
  static const double _accelerometerThreshold = 15.0;
  static const double _gyroscopeThreshold = 5.0;
  static const int _lowBatteryThreshold = 20;

  // Device health metrics
  final Map<String, dynamic> _deviceMetrics = {
    'batteryLevel': 100,
    'batteryState': 'unknown',
    'sensorStability': 'stable',
    'lastSensorError': null,
    'errorCount': 0,
  };

  // Initialize device monitoring
  static Future<void> initialize() async {
    try {
      await instance._startMonitoring();
      debugPrint('Device monitoring initialized successfully');
    } catch (e) {
      debugPrint('Device monitoring initialization failed: $e');
      // Continue without monitoring to prevent app crash
    }
  }

  // Start monitoring device sensors and battery
  Future<void> _startMonitoring() async {
    if (_isMonitoring) return;

    try {
      _isMonitoring = true;

      // Monitor battery state
      await _initializeBatteryMonitoring();

      // Monitor sensors with error handling
      await _initializeSensorMonitoring();

      // Setup periodic health checks
      _setupPeriodicHealthChecks();
    } catch (e) {
      debugPrint('Failed to start device monitoring: $e');
      _isMonitoring = false;
    }
  }

  // Initialize battery monitoring
  Future<void> _initializeBatteryMonitoring() async {
    try {
      // Get initial battery level
      final batteryLevel = await _battery.batteryLevel;
      _deviceMetrics['batteryLevel'] = batteryLevel;

      // Monitor battery state changes
      _batterySubscription = _battery.onBatteryStateChanged.listen(
        (BatteryState state) {
          _deviceMetrics['batteryState'] = state.toString();

          // Handle low battery scenarios
          if (_deviceMetrics['batteryLevel'] < _lowBatteryThreshold) {
            _handleLowBattery();
          }
        },
        onError: (error) {
          debugPrint('Battery monitoring error: $error');
          _deviceMetrics['lastSensorError'] = 'battery_error';
          _incrementErrorCount();
        },
      );

      // Periodic battery level updates
      Timer.periodic(const Duration(minutes: 5), (timer) async {
        if (!_isMonitoring) {
          timer.cancel();
          return;
        }

        try {
          final level = await _battery.batteryLevel;
          _deviceMetrics['batteryLevel'] = level;
        } catch (e) {
          debugPrint('Battery level check failed: $e');
        }
      });
    } catch (e) {
      debugPrint('Battery monitoring setup failed: $e');
    }
  }

  // Initialize sensor monitoring with error resilience
  Future<void> _initializeSensorMonitoring() async {
    try {
      // Monitor accelerometer with error handling
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          _handleAccelerometerData(event);
        },
        onError: (error) {
          debugPrint('Accelerometer error: $error');
          _deviceMetrics['lastSensorError'] = 'accelerometer_error';
          _incrementErrorCount();
          _handleSensorError('accelerometer', error);
        },
      );

      // Monitor gyroscope with error handling
      _gyroscopeSubscription = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          _handleGyroscopeData(event);
        },
        onError: (error) {
          debugPrint('Gyroscope error: $error');
          _deviceMetrics['lastSensorError'] = 'gyroscope_error';
          _incrementErrorCount();
          _handleSensorError('gyroscope', error);
        },
      );

      // Monitor magnetometer with error handling
      _magnetometerSubscription = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          _handleMagnetometerData(event);
        },
        onError: (error) {
          debugPrint('Magnetometer error: $error');
          _deviceMetrics['lastSensorError'] = 'magnetometer_error';
          _incrementErrorCount();
          _handleSensorError('magnetometer', error);
        },
      );
    } catch (e) {
      debugPrint('Sensor monitoring setup failed: $e');
    }
  }

  // Handle accelerometer data and detect instability
  void _handleAccelerometerData(AccelerometerEvent event) {
    try {
      final magnitude =
          (event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > _accelerometerThreshold) {
        _deviceMetrics['sensorStability'] = 'unstable';
        _handleHighAcceleration();
      } else {
        _deviceMetrics['sensorStability'] = 'stable';
      }
    } catch (e) {
      debugPrint('Accelerometer data processing error: $e');
    }
  }

  // Handle gyroscope data
  void _handleGyroscopeData(GyroscopeEvent event) {
    try {
      final magnitude =
          (event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > _gyroscopeThreshold) {
        // Device is rotating rapidly - might affect sensor accuracy
        _handleHighRotation();
      }
    } catch (e) {
      debugPrint('Gyroscope data processing error: $e');
    }
  }

  // Handle magnetometer data
  void _handleMagnetometerData(MagnetometerEvent event) {
    try {
      // Monitor magnetic field variations that might indicate sensor issues
      final magnitude =
          (event.x * event.x + event.y * event.y + event.z * event.z);

      // Log unusual magnetic field readings
      if (magnitude > 100 || magnitude < 10) {
        debugPrint('Unusual magnetic field detected: $magnitude');
      }
    } catch (e) {
      debugPrint('Magnetometer data processing error: $e');
    }
  }

  // Handle sensor errors gracefully
  void _handleSensorError(String sensorType, dynamic error) {
    debugPrint('$sensorType sensor error - attempting recovery');

    // Implement sensor recovery logic
    Timer(const Duration(seconds: 5), () {
      _attemptSensorRecovery(sensorType);
    });
  }

  // Attempt to recover from sensor errors
  void _attemptSensorRecovery(String sensorType) {
    try {
      switch (sensorType) {
        case 'accelerometer':
          _accelerometerSubscription?.cancel();
          _accelerometerSubscription = accelerometerEventStream().listen(
            (event) => _handleAccelerometerData(event),
            onError: (error) => _handleSensorError('accelerometer', error),
          );
          break;
        case 'gyroscope':
          _gyroscopeSubscription?.cancel();
          _gyroscopeSubscription = gyroscopeEventStream().listen(
            (event) => _handleGyroscopeData(event),
            onError: (error) => _handleSensorError('gyroscope', error),
          );
          break;
        case 'magnetometer':
          _magnetometerSubscription?.cancel();
          _magnetometerSubscription = magnetometerEventStream().listen(
            (event) => _handleMagnetometerData(event),
            onError: (error) => _handleSensorError('magnetometer', error),
          );
          break;
      }

      debugPrint('$sensorType sensor recovery attempted');
    } catch (e) {
      debugPrint('$sensorType sensor recovery failed: $e');
    }
  }

  // Handle low battery scenarios
  void _handleLowBattery() {
    debugPrint('Low battery detected - enabling power saving mode');

    // Reduce sensor sampling rates
    _reduceSensorFrequency();

    // Notify other services to reduce resource usage
    _deviceMetrics['powerSavingMode'] = true;
  }

  // Handle high acceleration events
  void _handleHighAcceleration() {
    debugPrint('High acceleration detected - device may be unstable');

    // Could indicate device dropping or shaking - pause sensitive operations
    _deviceMetrics['highMotion'] = true;

    // Reset after a delay
    Timer(const Duration(seconds: 3), () {
      _deviceMetrics['highMotion'] = false;
    });
  }

  // Handle high rotation events
  void _handleHighRotation() {
    debugPrint('High rotation detected');

    // Could indicate screen rotation or device spinning
    _deviceMetrics['highRotation'] = true;

    // Reset after a delay
    Timer(const Duration(seconds: 2), () {
      _deviceMetrics['highRotation'] = false;
    });
  }

  // Reduce sensor frequency for power saving
  void _reduceSensorFrequency() {
    // Cancel existing subscriptions
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();

    // Restart with reduced frequency (implementation depends on requirements)
    Timer(const Duration(seconds: 2), () {
      if (_isMonitoring) {
        _initializeSensorMonitoring();
      }
    });
  }

  // Setup periodic health checks
  void _setupPeriodicHealthChecks() {
    Timer.periodic(const Duration(minutes: 15), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }

      _performHealthCheck();
    });
  }

  // Perform comprehensive device health check
  void _performHealthCheck() {
    try {
      // Check error count
      final errorCount = _deviceMetrics['errorCount'] ?? 0;

      if (errorCount > 10) {
        debugPrint(
            'High error count detected: $errorCount - resetting monitoring');
        _resetMonitoring();
      }

      // Check battery level
      final batteryLevel = _deviceMetrics['batteryLevel'] ?? 100;
      if (batteryLevel < 10) {
        debugPrint(
            'Critical battery level: $batteryLevel% - enabling aggressive power saving');
        _enableAggressivePowerSaving();
      }

      // Reset error count periodically
      if (errorCount < 5) {
        _deviceMetrics['errorCount'] = 0;
      }
    } catch (e) {
      debugPrint('Health check failed: $e');
    }
  }

  // Reset monitoring system
  void _resetMonitoring() {
    _stopMonitoring();

    Timer(const Duration(seconds: 10), () {
      _startMonitoring();
    });
  }

  // Enable aggressive power saving
  void _enableAggressivePowerSaving() {
    _deviceMetrics['aggressivePowerSaving'] = true;

    // Disable non-essential monitoring
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();

    debugPrint('Aggressive power saving enabled - sensors disabled');
  }

  // Increment error count
  void _incrementErrorCount() {
    final currentCount = _deviceMetrics['errorCount'] ?? 0;
    _deviceMetrics['errorCount'] = currentCount + 1;
  }

  // Get device metrics for debugging
  Map<String, dynamic> getDeviceMetrics() {
    return Map.from(_deviceMetrics);
  }

  // Check if device is in good state
  bool isDeviceHealthy() {
    final errorCount = _deviceMetrics['errorCount'] ?? 0;
    final batteryLevel = _deviceMetrics['batteryLevel'] ?? 100;
    final sensorStability = _deviceMetrics['sensorStability'] ?? 'stable';

    return errorCount < 5 && batteryLevel > 20 && sensorStability == 'stable';
  }

  // Stop monitoring
  void _stopMonitoring() {
    _isMonitoring = false;

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _batterySubscription?.cancel();

    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _magnetometerSubscription = null;
    _batterySubscription = null;
  }

  // Dispose resources
  void dispose() {
    _stopMonitoring();
    _deviceMetrics.clear();
  }
}
