import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsTileWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? iconName;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color? titleColor;

  const SettingsTileWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.iconName,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
            child: Row(
              children: [
                if (iconName != null) ...[
                  CustomIconWidget(
                    iconName: iconName!,
                    size: 24,
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 3.w),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color: titleColor ??
                              AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          subtitle!,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: 2.w),
                  trailing!,
                ] else if (onTap != null) ...[
                  SizedBox(width: 2.w),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    size: 20,
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
            indent: iconName != null ? 15.w : 4.w,
            endIndent: 4.w,
          ),
      ],
    );
  }
}
