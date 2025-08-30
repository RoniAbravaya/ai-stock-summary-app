import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PortfolioOverviewWidget extends StatefulWidget {
  final double totalValue;
  final double percentageChange;
  final bool isPercentageView;
  final VoidCallback onToggleView;

  const PortfolioOverviewWidget({
    super.key,
    required this.totalValue,
    required this.percentageChange,
    required this.isPercentageView,
    required this.onToggleView,
  });

  @override
  State<PortfolioOverviewWidget> createState() =>
      _PortfolioOverviewWidgetState();
}

class _PortfolioOverviewWidgetState extends State<PortfolioOverviewWidget> {
  @override
  Widget build(BuildContext context) {
    final isPositive = widget.percentageChange >= 0;
    final changeColor = isPositive
        ? AppTheme.lightTheme.colorScheme.tertiary
        : AppTheme.lightTheme.colorScheme.error;

    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: widget.onToggleView,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Portfolio Value',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            widget.isPercentageView
                ? Text(
                    '${isPositive ? '+' : ''}${widget.percentageChange.toStringAsFixed(2)}%',
                    style:
                        AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Text(
                    '\$${widget.totalValue.toStringAsFixed(2)}',
                    style:
                        AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            SizedBox(height: 0.5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: isPositive ? 'trending_up' : 'trending_down',
                  color: changeColor,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  widget.isPercentageView
                      ? '\$${widget.totalValue.toStringAsFixed(2)}'
                      : '${isPositive ? '+' : ''}${widget.percentageChange.toStringAsFixed(2)}%',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Tap to toggle view',
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
