import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AnalyticsChartWidget extends StatefulWidget {
  const AnalyticsChartWidget({super.key});

  @override
  State<AnalyticsChartWidget> createState() => _AnalyticsChartWidgetState();
}

class _AnalyticsChartWidgetState extends State<AnalyticsChartWidget> {
  String selectedPeriod = '7D';
  final List<String> periods = ['7D', '30D', '90D', '1Y'];

  final List<Map<String, dynamic>> userGrowthData = [
    {"day": "Mon", "users": 45, "subscriptions": 12},
    {"day": "Tue", "users": 52, "subscriptions": 18},
    {"day": "Wed", "users": 38, "subscriptions": 8},
    {"day": "Thu", "users": 67, "subscriptions": 22},
    {"day": "Fri", "users": 84, "subscriptions": 31},
    {"day": "Sat", "users": 71, "subscriptions": 19},
    {"day": "Sun", "users": 59, "subscriptions": 15},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Growth Analytics',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'User registrations and subscription conversions',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPeriod,
                    isDense: true,
                    items: periods.map((String period) {
                      return DropdownMenuItem<String>(
                        value: period,
                        child: Text(
                          period,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textPrimaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedPeriod = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              _buildLegendItem('Users', AppTheme.primaryLight),
              SizedBox(width: 4.w),
              _buildLegendItem('Subscriptions', AppTheme.successLight),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppTheme.textPrimaryLight.withValues(alpha: 0.8),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label = rodIndex == 0 ? 'Users' : 'Subscriptions';
                      return BarTooltipItem(
                        '\$label: \${rod.toY.round()}',
                        AppTheme.lightTheme.textTheme.bodySmall!.copyWith(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() < userGrowthData.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Text(
                              userGrowthData[value.toInt()]["day"] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 3.h,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                        );
                      },
                      reservedSize: 8.w,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight, width: 1),
                    left: BorderSide(color: AppTheme.borderLight, width: 1),
                  ),
                ),
                barGroups: userGrowthData.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (data["users"] as int).toDouble(),
                        color: AppTheme.primaryLight,
                        width: 4.w,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: (data["subscriptions"] as int).toDouble(),
                        color: AppTheme.successLight,
                        width: 4.w,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.borderLight.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}