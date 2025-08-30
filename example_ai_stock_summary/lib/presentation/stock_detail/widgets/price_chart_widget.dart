import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PriceChartWidget extends StatefulWidget {
  final Map<String, dynamic> stockData;

  const PriceChartWidget({
    Key? key,
    required this.stockData,
  }) : super(key: key);

  @override
  State<PriceChartWidget> createState() => _PriceChartWidgetState();
}

class _PriceChartWidgetState extends State<PriceChartWidget> {
  String selectedPeriod = '1D';
  final List<String> periods = ['1D', '1W', '1M', '3M', '1Y'];

  List<FlSpot> get chartData {
    final List<dynamic> priceHistory =
        widget.stockData['priceHistory'] as List<dynamic>? ?? [];
    return priceHistory.asMap().entries.map((entry) {
      final index = entry.key;
      final price = (entry.value as num?)?.toDouble() ?? 0.0;
      return FlSpot(index.toDouble(), price);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double currentPrice =
        (widget.stockData['currentPrice'] as num?)?.toDouble() ?? 0.0;
    final double change =
        (widget.stockData['change'] as num?)?.toDouble() ?? 0.0;
    final bool isPositive = change >= 0;

    return Container(
      width: double.infinity,
      height: 45.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? AppTheme.shadowDark : AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Time period selector
          Container(
            padding: EdgeInsets.all(3.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: periods.map((period) {
                final isSelected = period == selectedPeriod;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPeriod = period;
                    });
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDarkMode
                              ? AppTheme.primaryDark
                              : AppTheme.primaryLight)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (isDarkMode
                                ? AppTheme.primaryDark
                                : AppTheme.primaryLight)
                            : (isDarkMode
                                ? AppTheme.borderDark
                                : AppTheme.borderLight),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      period,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? (isDarkMode
                                    ? AppTheme.onPrimaryDark
                                    : AppTheme.onPrimaryLight)
                                : (isDarkMode
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight),
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Chart
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: chartData.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: currentPrice * 0.02,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: (isDarkMode
                                      ? AppTheme.borderDark
                                      : AppTheme.borderLight)
                                  .withValues(alpha: 0.3),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: chartData.length > 10
                                  ? chartData.length / 5
                                  : 1,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    '${value.toInt()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDarkMode
                                              ? AppTheme.textSecondaryDark
                                              : AppTheme.textSecondaryLight,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              interval: currentPrice * 0.05,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    '\$${value.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDarkMode
                                              ? AppTheme.textSecondaryDark
                                              : AppTheme.textSecondaryLight,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: chartData.length > 1
                            ? (chartData.length - 1).toDouble()
                            : 1,
                        minY: chartData
                                .map((spot) => spot.y)
                                .reduce((a, b) => a < b ? a : b) *
                            0.98,
                        maxY: chartData
                                .map((spot) => spot.y)
                                .reduce((a, b) => a > b ? a : b) *
                            1.02,
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData,
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                isPositive
                                    ? (isDarkMode
                                        ? AppTheme.successDark
                                        : AppTheme.successLight)
                                    : (isDarkMode
                                        ? AppTheme.errorDark
                                        : AppTheme.errorLight),
                                isPositive
                                    ? (isDarkMode
                                            ? AppTheme.successDark
                                            : AppTheme.successLight)
                                        .withValues(alpha: 0.3)
                                    : (isDarkMode
                                            ? AppTheme.errorDark
                                            : AppTheme.errorLight)
                                        .withValues(alpha: 0.3),
                              ],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  isPositive
                                      ? (isDarkMode
                                              ? AppTheme.successDark
                                              : AppTheme.successLight)
                                          .withValues(alpha: 0.2)
                                      : (isDarkMode
                                              ? AppTheme.errorDark
                                              : AppTheme.errorLight)
                                          .withValues(alpha: 0.2),
                                  isPositive
                                      ? (isDarkMode
                                              ? AppTheme.successDark
                                              : AppTheme.successLight)
                                          .withValues(alpha: 0.05)
                                      : (isDarkMode
                                              ? AppTheme.errorDark
                                              : AppTheme.errorLight)
                                          .withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'show_chart',
                            color: isDarkMode
                                ? AppTheme.textDisabledDark
                                : AppTheme.textDisabledLight,
                            size: 48,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Chart data unavailable',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDarkMode
                                      ? AppTheme.textDisabledDark
                                      : AppTheme.textDisabledLight,
                                ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
