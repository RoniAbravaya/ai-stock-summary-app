import 'package:flutter/material.dart';

class ConnectionMonitorWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const ConnectionMonitorWidget({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            'Connections',
            metrics['activeConnections'].toString(),
            Icons.link,
            Colors.blue,
          ),
          _buildMetric(
            'Queries',
            metrics['queryCount'].toString(),
            Icons.storage,
            Colors.green,
          ),
          _buildMetric(
            'Avg Time',
            '${metrics['avgResponseTime']}ms',
            Icons.timer,
            Colors.orange,
          ),
          _buildMetric(
            'Operations',
            metrics['totalOperations'].toString(),
            Icons.analytics,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
