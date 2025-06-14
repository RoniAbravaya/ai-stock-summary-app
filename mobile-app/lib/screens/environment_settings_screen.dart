import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Environment Settings Screen
/// Allows easy switching between local and hosted endpoints during development
class EnvironmentSettingsScreen extends StatefulWidget {
  const EnvironmentSettingsScreen({super.key});

  @override
  State<EnvironmentSettingsScreen> createState() =>
      _EnvironmentSettingsScreenState();
}

class _EnvironmentSettingsScreenState extends State<EnvironmentSettingsScreen> {
  AppEnvironment _currentEnvironment = AppConfig.environment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Environment Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppConfig.environmentIndicator,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Environment',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConfig.environmentName,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'API URL: ${AppConfig.apiBaseUrl}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Environment Selection
            Text(
              'Select Environment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Local Environment
            _buildEnvironmentTile(
              environment: AppEnvironment.local,
              title: '🏠 Local Development',
              subtitle: 'http://localhost:3000/api',
              description: 'Use your local development server',
            ),

            const SizedBox(height: 12),

            // Development Environment
            _buildEnvironmentTile(
              environment: AppEnvironment.development,
              title: '🔧 Hosted Development',
              subtitle: 'Firebase hosted endpoint (development mode)',
              description:
                  'Use the hosted Firebase endpoint with development features',
            ),

            const SizedBox(height: 12),

            // Production Environment
            _buildEnvironmentTile(
              environment: AppEnvironment.production,
              title: '🚀 Production',
              subtitle: 'Firebase hosted endpoint (production)',
              description: 'Use the live hosted Firebase endpoint',
            ),

            const SizedBox(height: 32),

            // Warning Note
            if (_currentEnvironment != AppConfig.environment)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Restart Required',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'To change the environment, you need to update the AppConfig.environment constant and restart the app.',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentTile({
    required AppEnvironment environment,
    required String title,
    required String subtitle,
    required String description,
  }) {
    final isSelected = AppConfig.environment == environment;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading:
            isSelected
                ? Icon(Icons.radio_button_checked, color: Colors.blue[700])
                : Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue[700] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(description),
          ],
        ),
        onTap: () {
          setState(() {
            _currentEnvironment = environment;
          });

          _showEnvironmentChangeDialog(environment);
        },
      ),
    );
  }

  void _showEnvironmentChangeDialog(AppEnvironment environment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Switch to ${_getEnvironmentName(environment)}?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This will change the API endpoint to:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getEnvironmentUrl(environment),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'To apply this change, you need to:\n'
                  '1. Update AppConfig.environment in app_config.dart\n'
                  '2. Restart the application',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showInstructionsDialog(environment);
                },
                child: const Text('Show Instructions'),
              ),
            ],
          ),
    );
  }

  void _showInstructionsDialog(AppEnvironment environment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Environment Change Instructions'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To switch to ${_getEnvironmentName(environment)}:'),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Open mobile-app/lib/config/app_config.dart',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2. Change this line:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'static const AppEnvironment environment = AppEnvironment.production;',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                  const Text(
                    '3. To:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'static const AppEnvironment environment = AppEnvironment.${environment.name};',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Text(
                    '4. Save the file and restart the app',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
    );
  }

  String _getEnvironmentName(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.local:
        return 'Local Development';
      case AppEnvironment.development:
        return 'Hosted Development';
      case AppEnvironment.production:
        return 'Production';
    }
  }

  String _getEnvironmentUrl(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.local:
        return 'http://localhost:3000/api';
      case AppEnvironment.development:
        return 'https://ai-stock-summary-app--new-flutter-ai.us-central1.hosted.app/api';
      case AppEnvironment.production:
        return 'https://ai-stock-summary-app--new-flutter-ai.us-central1.hosted.app/api';
    }
  }
}
