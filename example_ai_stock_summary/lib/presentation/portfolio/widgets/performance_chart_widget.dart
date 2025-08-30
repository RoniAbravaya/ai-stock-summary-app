import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PerformanceChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> chartData;
  final VoidCallback? onPeriodChanged;

  const PerformanceChartWidget({
    Key? key,
    required this.chartData,
    this.onPeriodChanged,
  }) : super(key: key);

  @override
  State<PerformanceChartWidget> createState() => _PerformanceChartWidgetState();
}

class _PerformanceChartWidgetState extends State<PerformanceChartWidget>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = '1D';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _periods = ['1D', '1W', '1M', '3M', '1Y', 'All'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPeriodSelected(String period) {
    if (period != _selectedPeriod) {
      setState(() {
        _selectedPeriod = period;
      });
      _animationController.reset();
      _animationController.forward();
      widget.onPeriodChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
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
              Text(
                'Performance',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              CustomIconWidget(
                iconName: 'show_chart',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Period selector
          Container(
            height: 5.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _periods.length,
              itemBuilder: (context, index) {
                final period = _periods[index];
                final isSelected = period == _selectedPeriod;

                return GestureDetector(
                  onTap: () => _onPeriodSelected(period),
                  child: Container(
                    margin: EdgeInsets.only(right: 2.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        period,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 3.h),

          // Chart area
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              height: 25.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Grid lines
                  CustomPaint(
                    size: Size(double.infinity, 25.h),
                    painter: GridPainter(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                    ),
                  ),

                  // Chart line
                  CustomPaint(
                    size: Size(double.infinity, 25.h),
                    painter: ChartLinePainter(
                      data: widget.chartData,
                      lineColor: AppTheme.lightTheme.colorScheme.primary,
                      fillColor: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                    ),
                  ),

                  // Chart overlay
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'trending_up',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 32,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Portfolio Performance',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _selectedPeriod,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Performance metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem('High', '\$12,450.00',
                  AppTheme.lightTheme.colorScheme.tertiary),
              _buildMetricItem(
                  'Low', '\$11,200.00', AppTheme.lightTheme.colorScheme.error),
              _buildMetricItem(
                  'Change', '+5.2%', AppTheme.lightTheme.colorScheme.tertiary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    for (int i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChartLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color lineColor;
  final Color fillColor;

  ChartLinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Sample data points for demonstration
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.4),
      Offset(size.width, size.height * 0.2),
    ];

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
