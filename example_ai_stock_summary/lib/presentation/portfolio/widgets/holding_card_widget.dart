import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class HoldingCardWidget extends StatefulWidget {
  final Map<String, dynamic> holding;
  final VoidCallback? onTap;
  final VoidCallback? onSell;
  final VoidCallback? onAddShares;
  final VoidCallback? onRemove;
  final VoidCallback? onViewDetails;
  final VoidCallback? onGetAIAnalysis;
  final VoidCallback? onSetPriceAlert;

  const HoldingCardWidget({
    Key? key,
    required this.holding,
    this.onTap,
    this.onSell,
    this.onAddShares,
    this.onRemove,
    this.onViewDetails,
    this.onGetAIAnalysis,
    this.onSetPriceAlert,
  }) : super(key: key);

  @override
  State<HoldingCardWidget> createState() => _HoldingCardWidgetState();
}

class _HoldingCardWidgetState extends State<HoldingCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            _buildContextMenuItem(
              icon: 'info',
              title: 'View Details',
              onTap: widget.onViewDetails,
            ),
            _buildContextMenuItem(
              icon: 'psychology',
              title: 'Get AI Analysis',
              onTap: widget.onGetAIAnalysis,
            ),
            _buildContextMenuItem(
              icon: 'notifications',
              title: 'Set Price Alert',
              onTap: widget.onSetPriceAlert,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenuItem({
    required String icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: AppTheme.lightTheme.colorScheme.primary,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge,
      ),
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double gainLoss = (widget.holding['gainLoss'] as num).toDouble();
    final double gainLossPercentage =
        (widget.holding['gainLossPercentage'] as num).toDouble();
    final bool isPositive = gainLoss >= 0;
    final Color changeColor = isPositive
        ? AppTheme.lightTheme.colorScheme.tertiary
        : AppTheme.lightTheme.colorScheme.error;

    return Dismissible(
      key: Key(widget.holding['symbol'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomIconWidget(
              iconName: 'sell',
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 2.w),
            CustomIconWidget(
              iconName: 'add',
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 2.w),
            CustomIconWidget(
              iconName: 'delete',
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        _showSwipeActions(context);
        return false;
      },
      child: GestureDetector(
        onTap: () {
          _toggleExpanded();
          widget.onTap?.call();
        },
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
            children: [
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          (widget.holding['symbol'] as String).substring(0, 2),
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.holding['symbol'] as String,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.holding['companyName'] as String,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${(widget.holding['currentValue'] as num).toStringAsFixed(2)}',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName:
                                  isPositive ? 'trending_up' : 'trending_down',
                              color: changeColor,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${isPositive ? '+' : ''}\$${gainLoss.toStringAsFixed(2)}',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: changeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: _isExpanded ? 'expand_less' : 'expand_more',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ],
                ),
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface
                        .withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Column(
                    children: [
                      Divider(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                        height: 1,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem(
                              'Shares', '${widget.holding['shares']}'),
                          _buildDetailItem('Avg Cost',
                              '\$${(widget.holding['averageCost'] as num).toStringAsFixed(2)}'),
                          _buildDetailItem('Total Return',
                              '${isPositive ? '+' : ''}${gainLossPercentage.toStringAsFixed(2)}%'),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem('Allocation',
                              '${(widget.holding['allocationPercentage'] as num).toStringAsFixed(1)}%'),
                          _buildDetailItem('Current Price',
                              '\$${(widget.holding['currentPrice'] as num).toStringAsFixed(2)}'),
                          _buildDetailItem('Market Value',
                              '\$${(widget.holding['currentValue'] as num).toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showSwipeActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Quick Actions',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: 'sell',
                  label: 'Sell',
                  color: AppTheme.lightTheme.colorScheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSell?.call();
                  },
                ),
                _buildActionButton(
                  icon: 'add',
                  label: 'Add Shares',
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onAddShares?.call();
                  },
                ),
                _buildActionButton(
                  icon: 'delete',
                  label: 'Remove',
                  color: AppTheme.lightTheme.colorScheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onRemove?.call();
                  },
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                color: color,
                size: 24,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
