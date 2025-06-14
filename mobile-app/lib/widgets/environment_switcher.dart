import 'package:flutter/material.dart';
import '../config/app_config.dart';

class EnvironmentSwitcher extends StatefulWidget {
  const EnvironmentSwitcher({super.key});

  @override
  State<EnvironmentSwitcher> createState() => _EnvironmentSwitcherState();
}

class _EnvironmentSwitcherState extends State<EnvironmentSwitcher> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppEnvironment>(
      icon: Icon(
        AppConfig.environment == AppEnvironment.production
            ? Icons.cloud
            : Icons.computer,
        size: 20,
      ),
      tooltip: 'Environment: ${AppConfig.environmentName}',
      onSelected: (environment) {
        AppConfig.setEnvironment(environment);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${AppConfig.environmentName}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AppEnvironment.production,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud,
                color: AppConfig.environment == AppEnvironment.production
                    ? Colors.green
                    : null,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text('Production'),
            ],
          ),
        ),
        PopupMenuItem(
          value: AppEnvironment.local,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.computer,
                color: AppConfig.environment == AppEnvironment.local
                    ? Colors.green
                    : null,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text('Local'),
            ],
          ),
        ),
      ],
    );
  }
}
