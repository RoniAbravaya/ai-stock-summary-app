import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SubscriptionPreview extends StatelessWidget {
  const SubscriptionPreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Choose Your Plan',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              // Free Plan
              Expanded(
                child: _buildPlanCard(
                  title: 'Free',
                  price: '\$0',
                  features: [
                    '5 AI summaries/month',
                    'Basic portfolio tracking',
                    'Limited notifications',
                  ],
                  isPopular: false,
                ),
              ),

              SizedBox(width: 4.w),

              // Premium Plan
              Expanded(
                child: _buildPlanCard(
                  title: 'Premium',
                  price: '\$9.99',
                  features: [
                    'Unlimited AI summaries',
                    'Advanced analytics',
                    'Real-time alerts',
                    'Priority support',
                  ],
                  isPopular: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isPopular,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isPopular
            ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05)
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'POPULAR',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (isPopular) SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isPopular
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              if (price != '\$0')
                Text(
                  '/month',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          ...features
              .map((feature) => Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            feature,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}
