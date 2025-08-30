import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FloatingActionButtonsWidget extends StatefulWidget {
  final Map<String, dynamic> stockData;

  const FloatingActionButtonsWidget({
    Key? key,
    required this.stockData,
  }) : super(key: key);

  @override
  State<FloatingActionButtonsWidget> createState() =>
      _FloatingActionButtonsWidgetState();
}

class _FloatingActionButtonsWidgetState
    extends State<FloatingActionButtonsWidget> {
  bool isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    isInWatchlist = widget.stockData['isInWatchlist'] as bool? ?? false;
  }

  void _toggleWatchlist() {
    setState(() {
      isInWatchlist = !isInWatchlist;
    });

    Fluttertoast.showToast(
      msg: isInWatchlist
          ? '${widget.stockData['symbol']} added to watchlist'
          : '${widget.stockData['symbol']} removed from watchlist',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _setAlert() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAlertBottomSheet(),
    );
  }

  void _shareStock() {
    Fluttertoast.showToast(
      msg: 'Sharing ${widget.stockData['symbol']} details...',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Widget _buildAlertBottomSheet() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController priceController = TextEditingController();
    String alertType = 'above';

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
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
                    iconName: 'notifications',
                    color: isDarkMode
                        ? AppTheme.primaryDark
                        : AppTheme.primaryLight,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Set Price Alert',
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
              SizedBox(height: 2.h),
              Text(
                'Get notified when ${widget.stockData['symbol']} reaches your target price',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDarkMode
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Alert Type',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setModalState(() {
                          alertType = 'above';
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: alertType == 'above'
                              ? (isDarkMode
                                      ? AppTheme.primaryDark
                                      : AppTheme.primaryLight)
                                  .withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: alertType == 'above'
                                ? (isDarkMode
                                    ? AppTheme.primaryDark
                                    : AppTheme.primaryLight)
                                : (isDarkMode
                                    ? AppTheme.borderDark
                                    : AppTheme.borderLight),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'trending_up',
                              color: alertType == 'above'
                                  ? (isDarkMode
                                      ? AppTheme.primaryDark
                                      : AppTheme.primaryLight)
                                  : (isDarkMode
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight),
                              size: 20,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Above',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: alertType == 'above'
                                        ? (isDarkMode
                                            ? AppTheme.primaryDark
                                            : AppTheme.primaryLight)
                                        : (isDarkMode
                                            ? AppTheme.textSecondaryDark
                                            : AppTheme.textSecondaryLight),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setModalState(() {
                          alertType = 'below';
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        decoration: BoxDecoration(
                          color: alertType == 'below'
                              ? (isDarkMode
                                      ? AppTheme.primaryDark
                                      : AppTheme.primaryLight)
                                  .withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: alertType == 'below'
                                ? (isDarkMode
                                    ? AppTheme.primaryDark
                                    : AppTheme.primaryLight)
                                : (isDarkMode
                                    ? AppTheme.borderDark
                                    : AppTheme.borderLight),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'trending_down',
                              color: alertType == 'below'
                                  ? (isDarkMode
                                      ? AppTheme.primaryDark
                                      : AppTheme.primaryLight)
                                  : (isDarkMode
                                      ? AppTheme.textSecondaryDark
                                      : AppTheme.textSecondaryLight),
                              size: 20,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Below',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: alertType == 'below'
                                        ? (isDarkMode
                                            ? AppTheme.primaryDark
                                            : AppTheme.primaryLight)
                                        : (isDarkMode
                                            ? AppTheme.textSecondaryDark
                                            : AppTheme.textSecondaryLight),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Text(
                'Target Price',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
              ),
              SizedBox(height: 1.h),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter target price',
                  prefixText: '\$ ',
                  prefixStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                ),
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (priceController.text.isNotEmpty) {
                      Navigator.pop(context);
                      Fluttertoast.showToast(
                        msg:
                            'Price alert set for ${widget.stockData['symbol']} $alertType \$${priceController.text}',
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Set Alert',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppTheme.onPrimaryDark
                              : AppTheme.onPrimaryLight,
                        ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      right: 4.w,
      bottom: 4.h,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: "watchlist",
            onPressed: _toggleWatchlist,
            backgroundColor: isInWatchlist
                ? (isDarkMode ? AppTheme.errorDark : AppTheme.errorLight)
                : (isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight),
            child: CustomIconWidget(
              iconName: isInWatchlist ? 'favorite' : 'favorite_border',
              color: isInWatchlist
                  ? (isDarkMode ? AppTheme.onErrorDark : AppTheme.onErrorLight)
                  : (isDarkMode
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight),
              size: 24,
            ),
          ),
          SizedBox(height: 2.h),
          FloatingActionButton(
            heroTag: "alert",
            onPressed: _setAlert,
            backgroundColor:
                isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            child: CustomIconWidget(
              iconName: 'notifications',
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              size: 24,
            ),
          ),
          SizedBox(height: 2.h),
          FloatingActionButton(
            heroTag: "share",
            onPressed: _shareStock,
            backgroundColor:
                isDarkMode ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            child: CustomIconWidget(
              iconName: 'share',
              color: isDarkMode
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
