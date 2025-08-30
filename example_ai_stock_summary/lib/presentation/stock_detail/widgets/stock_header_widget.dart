import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StockHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> stockData;

  const StockHeaderWidget({
    Key? key,
    required this.stockData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double currentPrice =
        (stockData['currentPrice'] as num?)?.toDouble() ?? 0.0;
    final double change = (stockData['change'] as num?)?.toDouble() ?? 0.0;
    final double changePercent =
        (stockData['changePercent'] as num?)?.toDouble() ?? 0.0;
    final bool isPositive = change >= 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stockData['symbol'] as String? ?? 'N/A',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDarkMode
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      stockData['companyName'] as String? ?? 'Unknown Company',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDarkMode
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${currentPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? (isDarkMode
                                  ? AppTheme.successDark
                                  : AppTheme.successLight)
                              .withValues(alpha: 0.1)
                          : (isDarkMode
                                  ? AppTheme.errorDark
                                  : AppTheme.errorLight)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName:
                              isPositive ? 'trending_up' : 'trending_down',
                          color: isPositive
                              ? (isDarkMode
                                  ? AppTheme.successDark
                                  : AppTheme.successLight)
                              : (isDarkMode
                                  ? AppTheme.errorDark
                                  : AppTheme.errorLight),
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${isPositive ? '+' : ''}\$${change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isPositive
                                        ? (isDarkMode
                                            ? AppTheme.successDark
                                            : AppTheme.successLight)
                                        : (isDarkMode
                                            ? AppTheme.errorDark
                                            : AppTheme.errorLight),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
