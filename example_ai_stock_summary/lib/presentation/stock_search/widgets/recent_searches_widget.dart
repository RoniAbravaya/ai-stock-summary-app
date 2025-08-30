import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentSearchesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recentSearches;
  final Function(Map<String, dynamic>) onStockTap;
  final Function(String) onRemoveSearch;

  const RecentSearchesWidget({
    super.key,
    required this.recentSearches,
    required this.onStockTap,
    required this.onRemoveSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Clear all recent searches
                  for (var search in recentSearches) {
                    onRemoveSearch(search['ticker'] as String);
                  }
                },
                child: Text(
                  'Clear All',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentSearches.length,
          itemBuilder: (context, index) {
            final stock = recentSearches[index];
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                leading: Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: AppTheme.lightTheme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomImageWidget(
                      imageUrl: stock['logo'] as String,
                      width: 10.w,
                      height: 10.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      stock['ticker'] as String,
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      stock['companyName'] as String,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                subtitle: Text(
                  '\$${(stock['price'] as double).toStringAsFixed(2)}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: GestureDetector(
                  onTap: () => onRemoveSearch(stock['ticker'] as String),
                  child: Container(
                    padding: EdgeInsets.all(1.w),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
                onTap: () => onStockTap(stock),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: AppTheme.lightTheme.colorScheme.surface,
              ),
            );
          },
        ),
      ],
    );
  }
}
