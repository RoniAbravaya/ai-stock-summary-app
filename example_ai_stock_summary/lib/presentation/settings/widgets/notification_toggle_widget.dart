import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationToggleWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final String iconName;

  const NotificationToggleWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1)
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              size: 20,
              color: value
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.6),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.lightTheme.colorScheme.primary,
            inactiveThumbColor: AppTheme.lightTheme.colorScheme.outline,
            inactiveTrackColor:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
