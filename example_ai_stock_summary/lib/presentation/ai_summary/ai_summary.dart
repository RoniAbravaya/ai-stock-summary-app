import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/stock_model.dart';
import '../../services/ai_service.dart';
import './widgets/premium_upgrade_widget.dart';
import './widgets/related_stocks_widget.dart';
import './widgets/summary_content_widget.dart';
import './widgets/usage_indicator_widget.dart';

class AiSummary extends StatefulWidget {
  const AiSummary({super.key});

  @override
  State<AiSummary> createState() => _AiSummaryState();
}

class _AiSummaryState extends State<AiSummary> {
  bool _isLoading = false;
  bool _isBookmarked = false;
  bool _isRegenerating = false;
  bool _isStreaming = false;

  // User and summary data
  final bool _isPremium = false;
  final int _remainingSummaries = 2;

  StockModel? _stock;
  Map<String, dynamic>? _summaryData;
  String _streamingContent = '';

  // Mock related stocks data
  final List<Map<String, dynamic>> _relatedStocks = [
    {
      'symbol': 'MSFT',
      'companyName': 'Microsoft Corporation',
      'price': 378.85,
      'change': 4.23,
      'changePercent': 1.13,
    },
    {
      'symbol': 'GOOGL',
      'companyName': 'Alphabet Inc.',
      'price': 142.56,
      'change': -2.14,
      'changePercent': -1.48,
    },
    {
      'symbol': 'AMZN',
      'companyName': 'Amazon.com Inc.',
      'price': 145.32,
      'change': 1.87,
      'changePercent': 1.30,
    },
    {
      'symbol': 'TSLA',
      'companyName': 'Tesla Inc.',
      'price': 248.42,
      'change': -5.68,
      'changePercent': -2.24,
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStockData();
  }

  void _loadStockData() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      final stockId = args['stockId'] as String?;
      final stockSymbol = args['symbol'] as String?;

      if (stockId != null) {
        await _loadSummaryForStock(stockId);
      } else if (stockSymbol != null) {
        // Find stock by symbol and generate summary
        await _findStockBySymbolAndGenerate(stockSymbol);
      }
    }
  }

  Future<void> _loadSummaryForStock(String stockId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to get existing summary
      final existingSummary =
          await AiService.instance.getStockAiSummary(stockId);

      if (existingSummary != null) {
        _setupSummaryData(existingSummary);
      } else {
        // Generate new summary with OpenAI
        await _generateNewSummary(stockId);
      }
    } catch (error) {
      _showErrorSnackBar('Failed to load AI summary: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _findStockBySymbolAndGenerate(String symbol) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // This would typically involve finding the stock by symbol
      // For now, we'll generate a summary directly
      _showErrorSnackBar('Stock lookup by symbol not implemented');
    } catch (error) {
      _showErrorSnackBar('Failed to find stock: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNewSummary(String stockId) async {
    if (!_isPremium && _remainingSummaries <= 0) {
      _showUpgradeDialog();
      return;
    }

    try {
      final summary = await AiService.instance.generateAiSummaryWithOpenAI(
        stockId: stockId,
        saveToDatabase: true,
      );

      _setupSummaryData(summary);
    } catch (error) {
      _showErrorSnackBar('Failed to generate AI summary: $error');
    }
  }

  void _setupSummaryData(dynamic summary) {
    setState(() {
      if (summary.stockSymbol != null) {
        _stock = StockModel(
          id: summary.stockId,
          symbol: summary.stockSymbol!,
          name: summary.stockName!,
          exchange: summary.stockExchange ?? 'NASDAQ',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      _summaryData = {
        'executiveSummary': summary.summary,
        'financialHealth': summary.keyPoints ?? [],
        'marketPosition': summary.keyPoints ?? [],
        'investmentOutlook': {
          'recommendation': _extractRecommendation(summary.summary),
          'reasoning': summary.summary,
          'riskLevel': 'Medium'
        },
        'generatedAt': summary.generatedAt,
      };
    });
  }

  String _extractRecommendation(String summary) {
    final lowerSummary = summary.toLowerCase();
    if (lowerSummary.contains('buy') || lowerSummary.contains('bullish')) {
      return 'Buy';
    } else if (lowerSummary.contains('sell') ||
        lowerSummary.contains('bearish')) {
      return 'Sell';
    } else {
      return 'Hold';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.lightTheme.colorScheme.onSurface,
          size: 24,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _stock?.symbol ?? 'Loading...',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          Text(
            _stock?.name ?? 'Loading...',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _handleBookmark,
          icon: CustomIconWidget(
            iconName: _isBookmarked ? 'star' : 'star_border',
            color: _isBookmarked
                ? AppTheme.lightTheme.colorScheme.secondary
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        IconButton(
          onPressed: _handleShare,
          icon: CustomIconWidget(
            iconName: 'share',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        SizedBox(width: 2.w),
      ],
    );
  }

  Widget _buildContent() {
    if (_summaryData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              size: 48,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 2.h),
            Text(
              'No summary available',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            ElevatedButton(
              onPressed: () => _handleRegenerate(),
              child: Text('Generate Summary'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generation timestamp
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            color:
                AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
            child: Text(
              'Generated ${_formatTimestamp(_summaryData!['generatedAt'] as DateTime)}',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Usage indicator
          UsageIndicatorWidget(
            remainingSummaries: _remainingSummaries,
            isPremium: _isPremium,
          ),

          // Premium upgrade prompt (show for free users with low remaining summaries)
          if (!_isPremium && _remainingSummaries <= 1)
            PremiumUpgradeWidget(
              onUpgradeTap: _handlePremiumUpgrade,
            ),

          // Streaming content or summary content
          if (_isStreaming)
            _buildStreamingContent()
          else
            SummaryContentWidget(
              summaryData: _summaryData!,
            ),

          // Regenerate button
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: OutlinedButton.icon(
              onPressed: _isRegenerating ? null : _handleRegenerate,
              icon: _isRegenerating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    )
                  : CustomIconWidget(
                      iconName: 'refresh',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
              label: Text(
                _isRegenerating ? 'Regenerating...' : 'Regenerate Summary',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isRegenerating
                      ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                      : AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                side: BorderSide(
                  color: _isRegenerating
                      ? AppTheme.lightTheme.colorScheme.outline
                      : AppTheme.lightTheme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Related stocks
          RelatedStocksWidget(
            relatedStocks: _relatedStocks,
            onStockTap: _handleRelatedStockTap,
          ),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildStreamingContent() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Text(
                'Generating AI Summary...',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            _streamingContent.isEmpty
                ? 'Preparing analysis...'
                : _streamingContent,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Generating AI Summary...',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Using OpenAI to analyze market data',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _handleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBookmarked ? 'Summary bookmarked' : 'Bookmark removed',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.onSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleShare() {
    if (_summaryData == null) return;

    final shareText = '''
${_stock?.symbol} - ${_stock?.name} AI Summary

Executive Summary:
${_summaryData!['executiveSummary']}

Recommendation: ${(_summaryData!['investmentOutlook'] as Map)['recommendation']}

Generated by AI Stock Summary App with OpenAI
''';

    Clipboard.setData(ClipboardData(text: shareText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Summary copied to clipboard',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.onSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleRegenerate() async {
    if (!_isPremium && _remainingSummaries <= 0) {
      _showUpgradeDialog();
      return;
    }

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final stockId = args?['stockId'] as String?;

    if (stockId == null) {
      _showErrorSnackBar('Unable to regenerate: Stock ID not found');
      return;
    }

    setState(() {
      _isRegenerating = true;
      _isStreaming = true;
      _streamingContent = '';
    });

    try {
      // Stream the regeneration process
      await for (final chunk in AiService.instance.streamAiSummaryGeneration(
        stockId: stockId,
      )) {
        setState(() {
          _streamingContent += chunk;
        });
      }

      // Generate and save the final summary
      final newSummary = await AiService.instance.regenerateAiSummaryWithOpenAI(
        stockId: stockId,
      );

      _setupSummaryData(newSummary);

      _showSuccessSnackBar('Summary regenerated successfully with OpenAI');
    } catch (error) {
      _showErrorSnackBar('Failed to regenerate summary: $error');
    } finally {
      setState(() {
        _isRegenerating = false;
        _isStreaming = false;
        _streamingContent = '';
      });
    }
  }

  void _handlePremiumUpgrade() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  children: [
                    Text(
                      'Upgrade to Premium',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Get unlimited AI-powered summaries generated by OpenAI and advanced features to make better investment decisions.',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Premium upgrade feature coming soon!',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.lightTheme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        minimumSize: Size(double.infinity, 6.h),
                      ),
                      child: Text(
                        'Start 7-Day Free Trial',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Upgrade Required',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'You\'ve reached your free summary limit. Upgrade to Premium for unlimited AI-powered summaries.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handlePremiumUpgrade();
            },
            child: Text(
              'Upgrade',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRelatedStockTap(String symbol) {
    Navigator.pushNamed(context, '/stock-detail',
        arguments: {'symbol': symbol});
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
