import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptySearchWidget extends StatelessWidget {
  final String searchQuery;

  const EmptySearchWidget({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'search_off',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No stocks found',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              searchQuery.isNotEmpty
                  ? 'No results for "$searchQuery"'
                  : 'Try searching for a stock ticker or company name',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Suggestions:',
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Column(
              children: [
                _buildSuggestion('• Try different keywords'),
                _buildSuggestion('• Check the spelling'),
                _buildSuggestion(
                    '• Use stock ticker symbols (e.g., AAPL, GOOGL)'),
                _buildSuggestion(
                    '• Search for company names (e.g., Apple, Microsoft)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
