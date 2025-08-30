import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PopularStocksWidget extends StatelessWidget {
  final List<Map<String, dynamic>> popularStocks;
  final Function(Map<String, dynamic>) onStockTap;

  const PopularStocksWidget({
    super.key,
    required this.popularStocks,
    required this.onStockTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Text(
            'Popular Stocks',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 20.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: popularStocks.length,
            itemBuilder: (context, index) {
              final stock = popularStocks[index];
              final bool isPositive = (stock['change'] as double) >= 0;
              final Color changeColor = isPositive
                  ? AppTheme.lightTheme.colorScheme.tertiary
                  : AppTheme.lightTheme.colorScheme.error;

              return GestureDetector(
                onTap: () => onStockTap(stock),
                child: Container(
                  width: 40.w,
                  margin: EdgeInsets.only(right: 3.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.lightTheme.colorScheme.shadow,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: AppTheme
                                  .lightTheme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CustomImageWidget(
                                imageUrl: stock['logo'] as String,
                                width: 8.w,
                                height: 8.w,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: changeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: isPositive
                                      ? 'trending_up'
                                      : 'trending_down',
                                  color: changeColor,
                                  size: 12,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '${isPositive ? '+' : ''}${(stock['changePercent'] as double).toStringAsFixed(1)}%',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: changeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        stock['ticker'] as String,
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        stock['companyName'] as String,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '\$${(stock['price'] as double).toStringAsFixed(2)}',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${isPositive ? '+' : ''}\$${(stock['change'] as double).toStringAsFixed(2)}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
