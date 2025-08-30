import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AiSummaryWidget extends StatefulWidget {
  final Map<String, dynamic> stockData;

  const AiSummaryWidget({
    Key? key,
    required this.stockData,
  }) : super(key: key);

  @override
  State<AiSummaryWidget> createState() => _AiSummaryWidgetState();
}

class _AiSummaryWidgetState extends State<AiSummaryWidget> {
  bool isExpanded = false;
  bool isGenerating = false;
  String? aiSummary;

  @override
  void initState() {
    super.initState();
    aiSummary = widget.stockData['aiSummary'] as String?;
  }

  Future<void> _generateAiSummary() async {
    setState(() {
      isGenerating = true;
    });

    // Simulate AI summary generation
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      aiSummary =
          """Based on current market analysis, ${widget.stockData['symbol']} shows strong fundamentals with a current price of \$${((widget.stockData['currentPrice'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}. 

The stock has demonstrated solid performance with key metrics indicating healthy market positioning. Recent trading volume suggests active investor interest, while the P/E ratio of ${((widget.stockData['peRatio'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} reflects market confidence.

Technical indicators point to potential growth opportunities, though investors should consider market volatility and sector-specific risks. The company's market capitalization and trading patterns suggest institutional backing and retail investor confidence.

Overall assessment indicates a balanced investment opportunity with moderate risk profile suitable for diversified portfolios.""";
      isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? AppTheme.shadowDark : AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: (isDarkMode
                          ? AppTheme.primaryDark
                          : AppTheme.primaryLight)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'psychology',
                  color:
                      isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'AI Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          aiSummary == null
              ? Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: (isDarkMode
                                ? AppTheme.backgroundDark
                                : AppTheme.backgroundLight)
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? AppTheme.borderDark
                              : AppTheme.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          CustomIconWidget(
                            iconName: 'auto_awesome',
                            color: isDarkMode
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                            size: 32,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Get AI-powered insights for this stock',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDarkMode
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isGenerating ? null : _generateAiSummary,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isGenerating
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDarkMode
                                            ? AppTheme.onPrimaryDark
                                            : AppTheme.onPrimaryLight,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'Generating...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? AppTheme.onPrimaryDark
                                              : AppTheme.onPrimaryLight,
                                        ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'psychology',
                                    color: isDarkMode
                                        ? AppTheme.onPrimaryDark
                                        : AppTheme.onPrimaryLight,
                                    size: 20,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Get AI Summary',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? AppTheme.onPrimaryDark
                                              : AppTheme.onPrimaryLight,
                                        ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aiSummary!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDarkMode
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                            height: 1.6,
                          ),
                      maxLines: isExpanded ? null : 4,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    ),
                    if (aiSummary!.length > 200) ...[
                      SizedBox(height: 1.h),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: Text(
                          isExpanded ? 'Read Less' : 'Read More',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDarkMode
                                        ? AppTheme.primaryDark
                                        : AppTheme.primaryLight,
                                    fontWeight: FontWeight.w600,
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
}
