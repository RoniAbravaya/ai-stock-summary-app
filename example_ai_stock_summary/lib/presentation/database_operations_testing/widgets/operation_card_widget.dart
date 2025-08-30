import 'package:flutter/material.dart';

class OperationCardWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isRunning;
  final VoidCallback onTap;

  const OperationCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isRunning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isRunning ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: isRunning
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
