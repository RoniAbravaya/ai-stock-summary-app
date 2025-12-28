import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../screens/environment_settings_screen.dart';

/// Environment Indicator Widget
/// Shows the current environment status and allows quick access to environment settings
/// IMPORTANT: This widget is automatically hidden in production/release builds
/// per App Store Guideline 2.3.10 - metadata must not include development references
class EnvironmentIndicator extends StatelessWidget {
  final bool showInProduction;
  final VoidCallback? onTap;

  const EnvironmentIndicator({
    super.key,
    this.showInProduction = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Never show in release mode (App Store Guideline 2.3.10 compliance)
    // This ensures development indicators never appear in App Store builds
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }
    
    // Don't show in production unless explicitly requested
    if (AppConfig.isProduction && !showInProduction) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap ?? () => _showEnvironmentSettings(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _getEnvironmentColor().withOpacity(0.1),
          border: Border.all(color: _getEnvironmentColor(), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConfig.environmentIndicator,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              AppConfig.environmentName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getEnvironmentColor(),
              ),
            ),
            if (!AppConfig.isProduction) ...[
              const SizedBox(width: 4),
              Icon(Icons.settings, size: 12, color: _getEnvironmentColor()),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEnvironmentColor() {
    switch (AppConfig.environment) {
      case AppEnvironment.local:
        return Colors.green;
      case AppEnvironment.development:
        return Colors.orange;
      case AppEnvironment.production:
        return Colors.red;
    }
  }

  void _showEnvironmentSettings(BuildContext context) {
    if (AppConfig.isProduction) {
      _showEnvironmentInfo(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EnvironmentSettingsScreen(),
        ),
      );
    }
  }

  void _showEnvironmentInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Text(AppConfig.environmentIndicator),
                const SizedBox(width: 8),
                const Text('Environment Info'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Environment:', AppConfig.environmentName),
                _buildInfoRow('API Endpoint:', AppConfig.apiBaseUrl),
                _buildInfoRow('Version:', AppConfig.appVersion),
                _buildInfoRow('Build:', AppConfig.appBuildNumber),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Environment Banner Widget
/// Shows a banner at the top of the screen in non-production environments
/// IMPORTANT: This widget is automatically hidden in production/release builds
/// per App Store Guideline 2.3.10 - metadata must not include development references
class EnvironmentBanner extends StatelessWidget {
  final Widget child;

  const EnvironmentBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Never show banner in release mode (App Store Guideline 2.3.10 compliance)
    if (kReleaseMode || AppConfig.isProduction) {
      return child;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _getEnvironmentColor(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                AppConfig.environmentIndicator,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppConfig.environmentName} - ${AppConfig.apiBaseUrl}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => _showEnvironmentSettings(context),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Color _getEnvironmentColor() {
    switch (AppConfig.environment) {
      case AppEnvironment.local:
        return Colors.green;
      case AppEnvironment.development:
        return Colors.orange;
      case AppEnvironment.production:
        return Colors.red;
    }
  }

  void _showEnvironmentSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnvironmentSettingsScreen(),
      ),
    );
  }
}
