import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationFilterWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final Map<String, int> filterCounts;

  const NotificationFilterWidget({
    Key? key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filterCounts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': 'notifications'},
      {'key': 'price_alerts', 'label': 'Price Alerts', 'icon': 'trending_up'},
      {'key': 'news', 'label': 'News', 'icon': 'article'},
      {'key': 'ai_updates', 'label': 'AI Updates', 'icon': 'psychology'},
    ];

    return Container(
      height: 12.h,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['key'];
          final count = filterCounts[filter['key']] ?? 0;

          return GestureDetector(
            onTap: () => onFilterChanged(filter['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 3.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.shadow,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: filter['icon'] as String,
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    filter['label'] as String,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.onPrimary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.onPrimary
                                .withValues(alpha: 0.2)
                            : AppTheme.lightTheme.primaryColor
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.onPrimary
                              : AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
