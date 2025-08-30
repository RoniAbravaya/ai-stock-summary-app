import 'package:flutter/material.dart';

class QuickActionsWidget extends StatelessWidget {
  final bool isRunningTests;
  final VoidCallback onRunAllTests;
  final VoidCallback onClearLogs;
  final VoidCallback onExportResults;

  const QuickActionsWidget({
    super.key,
    required this.isRunningTests,
    required this.onRunAllTests,
    required this.onClearLogs,
    required this.onExportResults,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          onPressed: isRunningTests ? null : onRunAllTests,
          backgroundColor: Theme.of(context).primaryColor,
          icon: isRunningTests
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.play_arrow),
          label: Text(isRunningTests ? 'Running...' : 'Run All Tests'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: onClearLogs,
              backgroundColor: Colors.orange,
              mini: true,
              tooltip: 'Clear Logs',
              child: const Icon(Icons.clear_all),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: onExportResults,
              backgroundColor: Colors.blue,
              mini: true,
              tooltip: 'Export Results',
              child: const Icon(Icons.file_download),
            ),
          ],
        ),
      ],
    );
  }
}
