import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PortfolioAllocationWidget extends StatefulWidget {
  final List<Map<String, dynamic>> holdings;
  final VoidCallback? onSegmentTap;

  const PortfolioAllocationWidget({
    Key? key,
    required this.holdings,
    this.onSegmentTap,
  }) : super(key: key);

  @override
  State<PortfolioAllocationWidget> createState() =>
      _PortfolioAllocationWidgetState();
}

class _PortfolioAllocationWidgetState extends State<PortfolioAllocationWidget>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Color> _colors = [
    Color(0xFF1B365D),
    Color(0xFFFF6B35),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onSegmentTap(int index) {
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = -1;
        _animationController.reverse();
      } else {
        _selectedIndex = index;
        _animationController.forward();
      }
    });
    widget.onSegmentTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.holdings.isEmpty) {
      return SizedBox.shrink();
    }

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
                'Portfolio Allocation',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              CustomIconWidget(
                iconName: 'pie_chart',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Pie chart
          Center(
            child: Container(
              width: 50.w,
              height: 50.w,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(50.w, 50.w),
                    painter: PieChartPainter(
                      holdings: widget.holdings,
                      colors: _colors,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                  if (_selectedIndex >= 0 &&
                      _selectedIndex < widget.holdings.length)
                    Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.holdings[_selectedIndex]['symbol']
                                    as String,
                                style: AppTheme.lightTheme.textTheme.titleSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(widget.holdings[_selectedIndex]['allocationPercentage'] as num).toStringAsFixed(1)}%',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color:
                                      _colors[_selectedIndex % _colors.length],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Legend
          Wrap(
            spacing: 3.w,
            runSpacing: 1.h,
            children: widget.holdings.asMap().entries.map((entry) {
              final index = entry.key;
              final holding = entry.value;
              final color = _colors[index % _colors.length];
              final isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () => _onSegmentTap(index),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isSelected ? Border.all(color: color, width: 1) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 3.w,
                        height: 3.w,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        holding['symbol'] as String,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? color
                              : AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${(holding['allocationPercentage'] as num).toStringAsFixed(1)}%',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> holdings;
  final List<Color> colors;
  final int selectedIndex;

  PieChartPainter({
    required this.holdings,
    required this.colors,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (holdings.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < holdings.length; i++) {
      final holding = holdings[i];
      final percentage = (holding['allocationPercentage'] as num).toDouble();
      final sweepAngle = (percentage / 100) * 2 * math.pi;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final isSelected = selectedIndex == i;
      final currentRadius = isSelected ? radius * 1.05 : radius;

      // Draw pie segment
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle
    final centerPaint = Paint()
      ..color = AppTheme.lightTheme.colorScheme.surface
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.4, centerPaint);

    final centerBorderPaint = Paint()
      ..color = AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius * 0.4, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
