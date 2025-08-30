import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NewsSectionWidget extends StatelessWidget {
  final Map<String, dynamic> stockData;

  const NewsSectionWidget({
    Key? key,
    required this.stockData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> newsArticles = [
      {
        "id": 1,
        "headline":
            "${stockData['symbol']} Reports Strong Q3 Earnings, Beats Analyst Expectations",
        "summary":
            "The company delivered impressive quarterly results with revenue growth of 15% year-over-year, driven by strong demand in key markets.",
        "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
        "source": "Financial Times",
        "imageUrl":
            "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      },
      {
        "id": 2,
        "headline":
            "Market Analysis: ${stockData['companyName']} Positioned for Growth in 2024",
        "summary":
            "Industry experts highlight the company's strategic initiatives and market positioning as key drivers for future expansion.",
        "timestamp": DateTime.now().subtract(const Duration(hours: 6)),
        "source": "Bloomberg",
        "imageUrl":
            "https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      },
      {
        "id": 3,
        "headline":
            "Institutional Investors Increase Stakes in ${stockData['symbol']}",
        "summary":
            "Recent SEC filings show major institutional investors have increased their positions, signaling confidence in the stock.",
        "timestamp": DateTime.now().subtract(const Duration(hours: 12)),
        "source": "Reuters",
        "imageUrl":
            "https://images.unsplash.com/photo-1559526324-4b87b5e36e44?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      },
      {
        "id": 4,
        "headline":
            "Sector Outlook: Technology Stocks Show Resilience Amid Market Volatility",
        "summary":
            "Despite broader market concerns, technology companies continue to demonstrate strong fundamentals and growth potential.",
        "timestamp": DateTime.now().subtract(const Duration(days: 1)),
        "source": "Wall Street Journal",
        "imageUrl":
            "https://images.unsplash.com/photo-1551288049-bebda4e38f71?fm=jpg&q=60&w=400&ixlib=rb-4.0.3",
      },
    ];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'article',
                  color: isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Recent News',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: newsArticles.length,
              itemBuilder: (context, index) {
                final article = newsArticles[index];
                return Container(
                  width: 75.w,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 3.w,
                    right: index == newsArticles.length - 1 ? 0 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.cardDark : AppTheme.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? AppTheme.shadowDark
                            : AppTheme.shadowLight,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: CustomImageWidget(
                          imageUrl: article['imageUrl'] as String,
                          width: double.infinity,
                          height: 12.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article['headline'] as String,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? AppTheme.textPrimaryDark
                                          : AppTheme.textPrimaryLight,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 1.h),
                              Expanded(
                                child: Text(
                                  article['summary'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: isDarkMode
                                            ? AppTheme.textSecondaryDark
                                            : AppTheme.textSecondaryLight,
                                        height: 1.4,
                                      ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Row(
                                children: [
                                  Text(
                                    article['source'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDarkMode
                                              ? AppTheme.primaryDark
                                              : AppTheme.primaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatTimestamp(
                                        article['timestamp'] as DateTime),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDarkMode
                                              ? AppTheme.textDisabledDark
                                              : AppTheme.textDisabledLight,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}