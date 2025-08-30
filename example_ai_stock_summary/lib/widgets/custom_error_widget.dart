import 'package:flutter/material.dart';

import '../core/app_export.dart';
import '../services/device_monitoring_service.dart';

// Enhanced custom_error_widget.dart with device health awareness

class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final String? errorMessage;

  const CustomErrorWidget({
    Key? key,
    this.errorDetails,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get device health information
    final deviceMetrics = DeviceMonitoringService.instance.getDeviceMetrics();
    final isDeviceHealthy = DeviceMonitoringService.instance.isDeviceHealthy();

    // Determine error message based on device health
    final displayMessage = _getErrorMessage(deviceMetrics, isDeviceHealthy);
    final errorIcon = _getErrorIcon(deviceMetrics, isDeviceHealthy);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  errorIcon,
                  size: 64,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(height: 16),
                Text(
                  _getErrorTitle(deviceMetrics, isDeviceHealthy),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF262626),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF525252),
                    height: 1.5,
                  ),
                ),

                // Show device status if there are issues
                if (!isDeviceHealthy) ...[
                  const SizedBox(height: 16),
                  _buildDeviceStatusCard(deviceMetrics),
                ],

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _handleRetry(context);
                      },
                      icon: const Icon(Icons.refresh,
                          size: 18, color: Colors.white),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        _handleGoBack(context);
                      },
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Go Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.lightTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        side: BorderSide(
                          color: AppTheme.lightTheme.primaryColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get appropriate error title based on device health
  String _getErrorTitle(Map<String, dynamic> deviceMetrics, bool isHealthy) {
    if (!isHealthy) {
      final batteryLevel = deviceMetrics['batteryLevel'] ?? 100;
      final errorCount = deviceMetrics['errorCount'] ?? 0;

      if (batteryLevel < 20) {
        return 'Low Battery Detected';
      } else if (errorCount > 5) {
        return 'Device Issues Detected';
      } else {
        return 'System Optimization Needed';
      }
    }

    // Check for specific error types
    if (errorDetails != null) {
      final errorString = errorDetails!.exception.toString().toLowerCase();
      if (errorString.contains('sensor') ||
          errorString.contains('lux') ||
          errorString.contains('framebuffer')) {
        return 'Sensor Calibration Issue';
      }
    }

    return 'Something went wrong';
  }

  // Get appropriate error message based on device health and error type
  String _getErrorMessage(Map<String, dynamic> deviceMetrics, bool isHealthy) {
    if (!isHealthy) {
      final batteryLevel = deviceMetrics['batteryLevel'] ?? 100;
      final errorCount = deviceMetrics['errorCount'] ?? 0;
      final lastError = deviceMetrics['lastSensorError'];

      if (batteryLevel < 10) {
        return 'Your device battery is critically low. Please charge your device and try again.';
      } else if (batteryLevel < 20) {
        return 'Low battery may be affecting device performance. Consider charging your device.';
      } else if (errorCount > 10) {
        return 'Multiple device sensor errors detected. The app is running in safe mode to ensure stability.';
      } else if (lastError != null) {
        return 'Device sensor issues detected. The app will continue running with optimized performance settings.';
      }
    }

    // Check for specific system errors (like Xiaomi sensor issues)
    if (errorDetails != null) {
      final errorString = errorDetails!.exception.toString().toLowerCase();
      if (errorString.contains('sensor') ||
          errorString.contains('lux') ||
          errorString.contains('framebuffer') ||
          errorString.contains('xiaomi')) {
        return 'Your device\'s sensor system is experiencing minor calibration issues. This is a common system-level issue and doesn\'t affect the app\'s core functionality.';
      }
    }

    return errorMessage ??
        'We encountered an unexpected error while processing your request. The app will continue running normally.';
  }

  // Get appropriate error icon
  IconData _getErrorIcon(Map<String, dynamic> deviceMetrics, bool isHealthy) {
    if (!isHealthy) {
      final batteryLevel = deviceMetrics['batteryLevel'] ?? 100;
      if (batteryLevel < 20) {
        return Icons.battery_alert;
      }
      return Icons.warning_amber;
    }

    if (errorDetails != null) {
      final errorString = errorDetails!.exception.toString().toLowerCase();
      if (errorString.contains('sensor') ||
          errorString.contains('lux') ||
          errorString.contains('framebuffer')) {
        return Icons.sensors;
      }
    }

    return Icons.error_outline;
  }

  // Build device status information card
  Widget _buildDeviceStatusCard(Map<String, dynamic> metrics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                'Device Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (metrics['batteryLevel'] != null) ...[
            _buildStatusRow(
              'Battery Level',
              '${metrics['batteryLevel']}%',
              metrics['batteryLevel'] < 20,
            ),
          ],
          if (metrics['errorCount'] != null) ...[
            _buildStatusRow(
              'System Errors',
              '${metrics['errorCount']} detected',
              metrics['errorCount'] > 5,
            ),
          ],
          if (metrics['sensorStability'] != null) ...[
            _buildStatusRow(
              'Sensor Status',
              '${metrics['sensorStability']}',
              metrics['sensorStability'] != 'stable',
            ),
          ],
        ],
      ),
    );
  }

  // Build individual status row
  Widget _buildStatusRow(String label, String value, bool isWarning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  isWarning ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  // Handle retry action
  void _handleRetry(BuildContext context) {
    // Attempt to reinitialize services
    try {
      // Re-initialize device monitoring
      DeviceMonitoringService.initialize();

      // Navigate back to try the previous action again
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.initial);
      }
    } catch (e) {
      debugPrint('Retry failed: $e');
      _handleGoBack(context);
    }
  }

  // Handle go back action
  void _handleGoBack(BuildContext context) {
    bool canBeBack = Navigator.canPop(context);
    if (canBeBack) {
      Navigator.of(context).pop();
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.initial);
    }
  }
}
