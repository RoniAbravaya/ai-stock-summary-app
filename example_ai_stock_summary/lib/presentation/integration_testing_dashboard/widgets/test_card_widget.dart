import 'package:flutter/material.dart';

class TestCardWidget extends StatelessWidget {
  final String title;
  final String description;
  final bool isRunning;
  final VoidCallback onTest;

  const TestCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.isRunning,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isRunning ? null : onTest,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (isRunning)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.play_circle_filled,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
