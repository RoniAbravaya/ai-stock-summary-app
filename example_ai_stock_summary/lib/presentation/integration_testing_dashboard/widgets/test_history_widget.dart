import 'package:flutter/material.dart';
import '../integration_testing_dashboard.dart';

class TestHistoryWidget extends StatelessWidget {
  final List<TestResult> testHistory;

  const TestHistoryWidget({
    super.key,
    required this.testHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (testHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No test results yet'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: testHistory.take(10).length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final result = testHistory[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: result.success ? Colors.green : Colors.red,
                    child: Icon(
                      result.success ? Icons.check : Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(result.testName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.message),
                      Text(
                        '${result.executionTime}ms - ${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
