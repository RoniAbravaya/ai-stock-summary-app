import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class PerformanceMetricsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> metrics;
  final bool detailed;

  const PerformanceMetricsWidget({
    super.key,
    required this.metrics,
    this.detailed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    final latestMetric = metrics.last;
    final avgResponseTime = metrics
            .map((m) => m['apiResponseTime'] as int)
            .reduce((a, b) => a + b) /
        metrics.length;
    final avgSuccessRate =
        metrics.map((m) => m['successRate'] as double).reduce((a, b) => a + b) /
            metrics.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 24.sp,
                color: Colors.purple,
              ),
              SizedBox(width: 12.w),
              Text(
                'Performance Metrics',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Key metrics row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Response Time',
                  '${avgResponseTime.toInt()}ms',
                  Icons.timer,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildMetricCard(
                  'Success Rate',
                  '${avgSuccessRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),

          if (detailed) ...[
            SizedBox(height: 20.h),
            _buildPerformanceChart(),
          ],

          SizedBox(height: 20.h),

          // Latest performance status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Performance',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _buildPerformanceItem(
                      'API Response',
                      '${latestMetric['apiResponseTime']}ms',
                      _getPerformanceColor(
                          latestMetric['apiResponseTime'], 1000),
                    ),
                    SizedBox(width: 20.w),
                    _buildPerformanceItem(
                      'DB Query',
                      '${latestMetric['dbQueryTime']}ms',
                      _getPerformanceColor(latestMetric['dbQueryTime'], 500),
                    ),
                    SizedBox(width: 20.w),
                    _buildPerformanceItem(
                      'Success Rate',
                      '${latestMetric['successRate']}%',
                      _getPerformanceColor(latestMetric['successRate'], 95,
                          isPercentage: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return SizedBox(
      height: 150.h,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: metrics.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value['apiResponseTime'].toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withAlpha(26),
              ),
            ),
          ],
          minY: 0,
          maxY: metrics
                  .map((m) => m['apiResponseTime'] as int)
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble() *
              1.2,
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(dynamic value, num threshold,
      {bool isPercentage = false}) {
    if (isPercentage) {
      return value >= threshold
          ? Colors.green
          : value >= threshold * 0.8
              ? Colors.orange
              : Colors.red;
    } else {
      return value <= threshold
          ? Colors.green
          : value <= threshold * 1.5
              ? Colors.orange
              : Colors.red;
    }
  }
}