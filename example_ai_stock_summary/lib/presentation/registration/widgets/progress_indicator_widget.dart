import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ProgressIndicatorWidget({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${((currentStep / totalSteps) * 100).round()}%',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor:
              AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.lightTheme.colorScheme.primary,
          ),
          minHeight: 0.8.h,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
