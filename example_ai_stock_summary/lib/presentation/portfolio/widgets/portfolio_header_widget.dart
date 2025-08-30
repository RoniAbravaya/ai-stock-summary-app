import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PortfolioHeaderWidget extends StatelessWidget {
  final VoidCallback onRefresh;

  const PortfolioHeaderWidget({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portfolio Analysis',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: onRefresh,
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
          Container(
            height: 8.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'psychology',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'AI-Powered Insights',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
