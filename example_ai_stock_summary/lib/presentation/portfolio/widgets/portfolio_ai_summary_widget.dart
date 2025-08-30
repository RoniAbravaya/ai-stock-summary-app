import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/ai_summary_model.dart';
import '../../../services/ai_service.dart';
import '../../../services/supabase_service.dart';

class PortfolioAiSummaryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> holdings;
  final VoidCallback onRefresh;

  const PortfolioAiSummaryWidget({
    Key? key,
    required this.holdings,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<PortfolioAiSummaryWidget> createState() =>
      _PortfolioAiSummaryWidgetState();
}

class _PortfolioAiSummaryWidgetState extends State<PortfolioAiSummaryWidget> {
  bool _isLoading = false;
  List<AiSummaryModel> _portfolioSummaries = [];
  String _overallSentiment = 'neutral';
  double _averageConfidence = 0.0;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadPortfolioAiSummaries();
  }

  Future<void> _loadPortfolioAiSummaries() async {
    if (widget.holdings.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final summaries = <AiSummaryModel>[];

      // Get AI summaries for all portfolio holdings
      for (final holding in widget.holdings) {
        final summary =
            await AiService.instance.getStockAiSummary(holding['symbol']);
        if (summary != null) {
          summaries.add(summary);
        }
      }

      // Calculate overall portfolio sentiment and confidence
      if (summaries.isNotEmpty) {
        final sentiments = summaries.map((s) => s.sentiment).toList();
        final confidences = summaries
            .where((s) => s.confidenceScore != null)
            .map((s) => s.confidenceScore!)
            .toList();

        _overallSentiment = _calculateOverallSentiment(sentiments);
        _averageConfidence = confidences.isNotEmpty
            ? confidences.reduce((a, b) => a + b) / confidences.length
            : 0.0;
      }

      setState(() {
        _portfolioSummaries = summaries;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generatePortfolioAnalysis() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final analysis =
          await AiService.instance.generatePortfolioAnalysisWithOpenAI(
        userId: userId,
      );

      // Show analysis in a dialog or navigate to detailed view
      _showPortfolioAnalysisDialog(analysis);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to generate portfolio analysis: $error',
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
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showPortfolioAnalysisDialog(Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'AI Portfolio Analysis',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Summary:',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                analysis['summary'] ?? 'No summary available',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Key Recommendations:',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 1.h),
              if (analysis['recommendations'] != null)
                ...((analysis['recommendations'] as List).map((rec) => Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Text(
                        '• $rec',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                    ))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateOverallSentiment(List<String> sentiments) {
    final sentimentCounts = <String, int>{};
    for (final sentiment in sentiments) {
      sentimentCounts[sentiment.toLowerCase()] =
          (sentimentCounts[sentiment.toLowerCase()] ?? 0) + 1;
    }

    if (sentimentCounts.isEmpty) return 'neutral';

    // Return the most common sentiment
    return sentimentCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Color _getSentimentColor() {
    switch (_overallSentiment.toLowerCase()) {
      case 'bullish':
        return const Color(0xFF10B981);
      case 'bearish':
        return const Color(0xFFEF4444);
      case 'neutral':
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getSentimentIcon() {
    switch (_overallSentiment.toLowerCase()) {
      case 'bullish':
        return Icons.trending_up;
      case 'bearish':
        return Icons.trending_down;
      case 'neutral':
      default:
        return Icons.trending_flat;
    }
  }

  String _getSentimentDisplay() {
    switch (_overallSentiment.toLowerCase()) {
      case 'bullish':
        return 'Bullish';
      case 'bearish':
        return 'Bearish';
      case 'neutral':
      default:
        return 'Neutral';
    }
  }

  String _getConfidenceDisplay() {
    if (_averageConfidence >= 0.8) {
      return 'High Confidence';
    } else if (_averageConfidence >= 0.6) {
      return 'Medium Confidence';
    } else if (_averageConfidence >= 0.4) {
      return 'Low Confidence';
    } else {
      return 'Very Low Confidence';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.holdings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'psychology',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'AI Portfolio Insights',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  widget.onRefresh();
                  await _loadPortfolioAiSummaries();
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'refresh',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          if (_isLoading)
            // Loading state
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Analyzing portfolio...',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else if (_portfolioSummaries.isEmpty)
            // No summaries state
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: 'lightbulb_outline',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'AI insights coming soon',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'AI analysis will be available for your holdings',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            // AI Summary content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall sentiment
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: _getSentimentColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getSentimentColor().withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getSentimentIcon(),
                        color: _getSentimentColor(),
                        size: 24,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portfolio Sentiment: ${_getSentimentDisplay()}',
                              style: AppTheme.lightTheme.textTheme.bodyLarge
                                  ?.copyWith(
                                color: _getSentimentColor(),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              _getConfidenceDisplay(),
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: _getSentimentColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),

                // Holdings with AI summaries
                Text(
                  'Stock Insights (${_portfolioSummaries.length}/${widget.holdings.length})',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _portfolioSummaries.take(3).length,
                  separatorBuilder: (context, index) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    final summary = _portfolioSummaries[index];
                    return _buildSummaryTile(summary);
                  },
                ),

                if (_portfolioSummaries.length > 3) ...[
                  SizedBox(height: 1.h),
                  GestureDetector(
                    onTap: () => _showAllSummaries(),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 2.w, horizontal: 3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View ${_portfolioSummaries.length - 3} more insights',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          CustomIconWidget(
                            iconName: 'arrow_forward',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(AiSummaryModel summary) {
    final sentimentColor = Color(
      int.parse(summary.sentimentColor.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: sentimentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              summary.sentiment.toLowerCase() == 'bullish'
                  ? Icons.trending_up
                  : summary.sentiment.toLowerCase() == 'bearish'
                      ? Icons.trending_down
                      : Icons.trending_flat,
              color: sentimentColor,
              size: 16,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      summary.stockSymbol ?? '',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: sentimentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        summary.sentimentDisplayName,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: sentimentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  summary.preview,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  summary.timeAgo,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllSummaries() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        height: 80.h,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Title
            Text(
              'Portfolio AI Insights',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            // All summaries
            Expanded(
              child: ListView.separated(
                itemCount: _portfolioSummaries.length,
                separatorBuilder: (context, index) => SizedBox(height: 1.h),
                itemBuilder: (context, index) {
                  final summary = _portfolioSummaries[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/ai-summary',
                        arguments: summary.stockSymbol,
                      );
                    },
                    child: _buildSummaryTile(summary),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
