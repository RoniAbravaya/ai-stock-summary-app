import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyNotificationsWidget extends StatelessWidget {
  final String filterType;
  final VoidCallback? onSetupNotifications;

  const EmptyNotificationsWidget({
    Key? key,
    required this.filterType,
    this.onSetupNotifications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emptyStateData = _getEmptyStateData(filterType);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: emptyStateData['color'].withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: emptyStateData['icon'],
                  color: emptyStateData['color'],
                  size: 60,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              emptyStateData['title'],
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              emptyStateData['description'],
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            if (emptyStateData['showSetupButton']) ...[
              ElevatedButton.icon(
                onPressed: onSetupNotifications,
                icon: CustomIconWidget(
                  iconName: 'settings',
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: Text('Setup Notifications'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                ),
              ),
              SizedBox(height: 2.h),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/stock-search'),
                child: Text(
                  'Browse Stocks',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                icon: CustomIconWidget(
                  iconName: 'home',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 20,
                ),
                label: Text('Go to Dashboard'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getEmptyStateData(String filterType) {
    switch (filterType) {
      case 'price_alerts':
        return {
          'icon': 'trending_up',
          'color': AppTheme.lightTheme.colorScheme.tertiary,
          'title': 'No Price Alerts',
          'description':
              'Set up price alerts for your favorite stocks to get notified when they reach your target prices.',
          'showSetupButton': true,
        };
      case 'news':
        return {
          'icon': 'article',
          'color': AppTheme.lightTheme.colorScheme.secondary,
          'title': 'No News Updates',
          'description':
              'Stay informed with the latest market news and updates. Follow stocks to receive relevant news notifications.',
          'showSetupButton': true,
        };
      case 'ai_updates':
        return {
          'icon': 'psychology',
          'color': AppTheme.lightTheme.primaryColor,
          'title': 'No AI Updates',
          'description':
              'Get AI-powered insights and analysis for your portfolio. Generate AI summaries to receive intelligent market updates.',
          'showSetupButton': false,
        };
      default:
        return {
          'icon': 'notifications_none',
          'color': AppTheme.lightTheme.colorScheme.outline,
          'title': 'No Notifications',
          'description':
              'You\'re all caught up! When you receive notifications, they\'ll appear here for easy access and management.',
          'showSetupButton': true,
        };
    }
  }
}
