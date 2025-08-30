import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AdminHeaderWidget extends StatelessWidget {
  final int totalUsers;
  final int activeSubscriptions;
  final int dailyNotifications;

  const AdminHeaderWidget({
    super.key,
    required this.totalUsers,
    required this.activeSubscriptions,
    required this.dailyNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
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
                    'Admin Dashboard',
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryLight.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'admin_panel_settings',
                          color: AppTheme.primaryLight,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Administrator',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CustomIconWidget(
                iconName: 'notifications',
                color: AppTheme.textSecondaryLight,
                size: 24,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  totalUsers.toString(),
                  'people',
                  AppTheme.primaryLight,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatCard(
                  'Active Subs',
                  activeSubscriptions.toString(),
                  'star',
                  AppTheme.successLight,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatCard(
                  'Daily Alerts',
                  dailyNotifications.toString(),
                  'send',
                  AppTheme.secondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, String iconName, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: color,
                size: 20,
              ),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
