import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ThemeSelectorWidget extends StatelessWidget {
  final String selectedTheme;
  final Function(String) onThemeChanged;

  const ThemeSelectorWidget({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      {"name": "Light", "icon": "light_mode"},
      {"name": "Dark", "icon": "dark_mode"},
      {"name": "System", "icon": "settings_brightness"},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: themes.map((theme) {
          final isSelected = selectedTheme == theme["name"];
          return GestureDetector(
            onTap: () => onThemeChanged(theme["name"] as String),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: theme["icon"] as String,
                    size: 24,
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    theme["name"] as String,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.onPrimary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
