import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/ai_summary_widget.dart';
import './widgets/floating_action_buttons_widget.dart';
import './widgets/key_metrics_widget.dart';
import './widgets/news_section_widget.dart';
import './widgets/price_chart_widget.dart';
import './widgets/stock_header_widget.dart';

class StockDetail extends StatefulWidget {
  const StockDetail({Key? key}) : super(key: key);

  @override
  State<StockDetail> createState() => _StockDetailState();
}

class _StockDetailState extends State<StockDetail> {
  bool isLoading = true;
  bool showTechnicalIndicators = false;
  late Map<String, dynamic> stockData;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    // Simulate loading stock data
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      stockData = {
        "symbol": "AAPL",
        "companyName": "Apple Inc.",
        "currentPrice": 175.43,
        "change": 2.87,
        "changePercent": 1.66,
        "open": 173.50,
        "high": 176.12,
        "low": 172.88,
        "volume": 45678900,
        "marketCap": 2750000000000,
        "peRatio": 28.45,
        "isInWatchlist": false,
        "priceHistory": [
          170.25,
          171.80,
          169.45,
          172.30,
          174.15,
          173.60,
          175.43,
          176.20,
          174.85,
          173.90,
          175.10,
          176.45,
          175.80,
          174.30,
          173.75,
          175.20,
          176.80,
          175.43
        ],
        "aiSummary": null,
      };
      isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _loadStockData();
  }

  void _showTechnicalIndicators() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'analytics',
                  color:
                      isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Technical Indicators',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: isDarkMode
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    size: 24,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            _buildIndicatorTile('Moving Averages', 'MA', isDarkMode),
            _buildIndicatorTile('Relative Strength Index', 'RSI', isDarkMode),
            _buildIndicatorTile('MACD', 'MACD', isDarkMode),
            _buildIndicatorTile('Bollinger Bands', 'BB', isDarkMode),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorTile(String title, String subtitle, bool isDarkMode) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: (isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: 'show_chart',
            color: isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDarkMode
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
        ),
        trailing: Switch(
          value: showTechnicalIndicators,
          onChanged: (value) {
            setState(() {
              showTechnicalIndicators = value;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          isLoading ? 'Loading...' : stockData['symbol'] as String,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: isDarkMode
                ? AppTheme.textPrimaryDark
                : AppTheme.textPrimaryLight,
            size: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showTechnicalIndicators,
            icon: CustomIconWidget(
              iconName: 'analytics',
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _refreshData,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              size: 24,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading stock details...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _refreshData,
                  color:
                      isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stock Header
                        StockHeaderWidget(stockData: stockData),

                        // Price Chart
                        PriceChartWidget(stockData: stockData),

                        // Key Metrics
                        KeyMetricsWidget(stockData: stockData),

                        // AI Summary
                        AiSummaryWidget(stockData: stockData),

                        // News Section
                        NewsSectionWidget(stockData: stockData),

                        // Bottom padding for floating buttons
                        SizedBox(height: 25.h),
                      ],
                    ),
                  ),
                ),

                // Floating Action Buttons
                FloatingActionButtonsWidget(stockData: stockData),
              ],
            ),
    );
  }
}
