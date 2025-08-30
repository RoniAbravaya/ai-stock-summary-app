import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class KeyMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> stockData;

  const KeyMetricsWidget({
    Key? key,
    required this.stockData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, String>> metrics = [
      {
        'label': 'Open',
        'value':
            '\$${((stockData['open'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
      },
      {
        'label': 'High',
        'value':
            '\$${((stockData['high'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
      },
      {
        'label': 'Low',
        'value':
            '\$${((stockData['low'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
      },
      {
        'label': 'Volume',
        'value':
            _formatVolume((stockData['volume'] as num?)?.toDouble() ?? 0.0),
      },
      {
        'label': 'Market Cap',
        'value': _formatMarketCap(
            (stockData['marketCap'] as num?)?.toDouble() ?? 0.0),
      },
      {
        'label': 'P/E Ratio',
        'value': ((stockData['peRatio'] as num?)?.toDouble() ?? 0.0)
            .toStringAsFixed(2),
      },
    ];

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
          Text(
            'Key Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
          ),
          SizedBox(height: 2.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 2.h,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: (isDarkMode
                          ? AppTheme.backgroundDark
                          : AppTheme.backgroundLight)
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDarkMode ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      metric['label'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      metric['value'] ?? 'N/A',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toStringAsFixed(0);
  }

  String _formatMarketCap(double marketCap) {
    if (marketCap >= 1000000000000) {
      return '\$${(marketCap / 1000000000000).toStringAsFixed(2)}T';
    } else if (marketCap >= 1000000000) {
      return '\$${(marketCap / 1000000000).toStringAsFixed(2)}B';
    } else if (marketCap >= 1000000) {
      return '\$${(marketCap / 1000000).toStringAsFixed(2)}M';
    }
    return '\$${marketCap.toStringAsFixed(0)}';
  }
}
