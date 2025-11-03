import 'package:flutter/material.dart';
import '../services/user_data_service.dart';

/// Widget to display user's AI summary usage statistics
class UsageStatsCard extends StatefulWidget {
  const UsageStatsCard({super.key});

  @override
  State<UsageStatsCard> createState() => _UsageStatsCardState();
}

class _UsageStatsCardState extends State<UsageStatsCard> {
  final UserDataService _userDataService = UserDataService();
  
  Map<String, dynamic>? _usageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    try {
      final usageData = await _userDataService.getUsageData();
      setState(() {
        _usageData = usageData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading usage data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_usageData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Failed to load usage data'),
        ),
      );
    }

    final summariesUsed = _usageData!['summariesUsed'] as int;
    final summariesLimit = _usageData!['summariesLimit'] as int;
    final subscriptionType = _usageData!['subscriptionType'] ?? 'free';
    final usageHistory = _usageData!['usageHistory'] as Map<String, dynamic>?;
    final percentage = (summariesUsed / summariesLimit * 100).clamp(0, 100);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Summary Usage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildSubscriptionBadge(subscriptionType, theme),
              ],
            ),
            const SizedBox(height: 16),

            // Current month usage
            Text(
              'This Month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$summariesUsed / $summariesLimit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${summariesLimit - summariesUsed} summaries remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: summariesUsed >= summariesLimit
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Reset date
            FutureBuilder<int>(
              future: _userDataService.getDaysUntilReset(),
              builder: (context, snapshot) {
                final daysUntilReset = snapshot.data ?? 0;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade900
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Resets in $daysUntilReset days (1st of next month)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Usage history
            if (usageHistory != null && usageHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Usage History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildUsageHistory(usageHistory, theme, isDark),
            ],

            // Upgrade prompt for free users
            if (subscriptionType == 'free' && summariesUsed >= summariesLimit - 2)
              ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: 20,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Upgrade to Premium',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get 100 AI summaries per month with premium subscription!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to subscription page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Premium subscription coming soon!'),
                            ),
                          );
                        },
                        child: const Text('Learn More'),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge(String subscriptionType, ThemeData theme) {
    final Color color;
    final IconData icon;
    final String label;

    switch (subscriptionType) {
      case 'premium':
        color = Colors.amber;
        icon = Icons.workspace_premium;
        label = 'Premium';
        break;
      case 'admin':
        color = Colors.purple;
        icon = Icons.admin_panel_settings;
        label = 'Admin';
        break;
      default:
        color = Colors.grey;
        icon = Icons.person;
        label = 'Free';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageHistory(
    Map<String, dynamic> history,
    ThemeData theme,
    bool isDark,
  ) {
    // Sort history by month (most recent first)
    final sortedMonths = history.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedMonths.take(6).map((monthKey) {
        final monthData = history[monthKey] as Map<String, dynamic>;
        final used = monthData['used'] as int;
        final limit = monthData['limit'] as int;
        final percentage = (used / limit * 100).clamp(0, 100);

        // Parse month key (e.g., "2025-11")
        final parts = monthKey.split('-');
        final year = int.tryParse(parts[0]) ?? 0;
        final month = int.tryParse(parts[1]) ?? 0;
        final monthName = _getMonthName(month);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  '$monthName $year',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Text(
                  '$used / $limit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
