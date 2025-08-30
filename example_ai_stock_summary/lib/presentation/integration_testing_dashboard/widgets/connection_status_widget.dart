import 'package:flutter/material.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final Map<String, bool> connectionStatus;

  const ConnectionStatusWidget({
    super.key,
    required this.connectionStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusIndicator(
            'Network',
            connectionStatus['network'] ?? false,
            Icons.wifi,
          ),
          _buildStatusIndicator(
            'Supabase',
            connectionStatus['supabase'] ?? false,
            Icons.storage,
          ),
          _buildStatusIndicator(
            'OpenAI',
            connectionStatus['openai'] ?? false,
            Icons.psychology,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isConnected, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
