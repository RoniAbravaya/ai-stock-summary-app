import 'package:flutter/material.dart';
import '../services/stock_service.dart';
import '../services/user_data_service.dart';
import '../services/firebase_service.dart';

/// Dialog that shows AI summary with usage tracking and limits
class AISummaryDialog extends StatefulWidget {
  const AISummaryDialog({
    super.key,
    required this.ticker,
    required this.stockName,
  });

  final String ticker;
  final String stockName;

  @override
  State<AISummaryDialog> createState() => _AISummaryDialogState();
}

class _AISummaryDialogState extends State<AISummaryDialog> {
  final StockService _stockService = StockService();
  final UserDataService _userDataService = UserDataService();
  
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _summary;
  String? _error;
  Map<String, dynamic>? _usageInfo;

  @override
  void initState() {
    super.initState();
    _loadUsageAndSummary();
  }

  Future<void> _loadUsageAndSummary() async {
    try {
      // Load current usage info
      final usageData = await _userDataService.getUsageData();
      setState(() {
        _usageInfo = usageData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load usage data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateSummary() async {
    if (_usageInfo == null) return;

    final summariesUsed = _usageInfo!['summariesUsed'] as int;
    final summariesLimit = _usageInfo!['summariesLimit'] as int;
    final subscriptionType = _usageInfo!['subscriptionType'] ?? 'free';
    final role = _usageInfo!['role'] ?? 'user';

    // Check if user is at limit (admins are unlimited)
    if (role != 'admin' && summariesUsed >= summariesLimit) {
      await _showLimitExceededDialog();
      return;
    }

    // Show warning if user is near limit
    if (role != 'admin' && 
        subscriptionType == 'free' && 
        summariesUsed >= summariesLimit - 1) {
      final shouldContinue = await _showNearLimitWarning();
      if (!shouldContinue) return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      // Get Firebase auth token for API authentication
      final user = FirebaseService().currentUser;
      if (user == null) {
        throw Exception('Please sign in to generate AI summaries');
      }

      final idToken = await user.getIdToken();
      
      // Generate the summary
      final summary = await _stockService.generateAISummary(
        widget.ticker,
        language: 'en', // TODO: Use user's preferred language
      );

      // Track usage locally
      await _userDataService.trackSummaryUsage();

      // Reload usage info
      await _loadUsageAndSummary();

      setState(() {
        _summary = summary;
        _isGenerating = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI Summary generated! ${summariesLimit - summariesUsed - 1} remaining this month.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });

      // Check if error is about limit exceeded
      if (e.toString().contains('429') || e.toString().contains('limit')) {
        await _showLimitExceededDialog();
      }
    }
  }

  Future<bool> _showNearLimitWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('?? Near Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to use your last AI summary for this month.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Free users get 5 AI summaries per month. Your limit will reset on the 1st of next month.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Do you want to continue?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showLimitExceededDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('?? Limit Reached'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have used all 5 AI summaries for this month.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Your limit will reset on the 1st of next month.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '?? Upgrade to Premium',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get 100 AI summaries per month with a premium subscription!',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to subscription page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium subscription coming soon!'),
                ),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Summary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          widget.stockName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Usage indicator
            if (_usageInfo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Used ${_usageInfo!['summariesUsed']}/${_usageInfo!['summariesLimit']} this month',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (_usageInfo!['role'] != 'admin')
                      Text(
                        '${_usageInfo!['summariesLimit'] - _usageInfo!['summariesUsed']} remaining',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildContent(theme),
              ),
            ),

            // Actions
            if (!_isLoading && _summary == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateSummary,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating
                      ? 'Generating...'
                      : 'Generate AI Summary'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (_summary != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _summary!,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Generated just now for ${widget.ticker}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Generate an AI-powered summary',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Get insights on recent trends, news, and potential risks for ${widget.ticker}',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
