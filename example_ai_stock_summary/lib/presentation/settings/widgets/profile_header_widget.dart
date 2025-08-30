import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final VoidCallback onEditProfile;

  const ProfileHeaderWidget({
    super.key,
    required this.userProfile,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onEditProfile,
            child: Stack(
              children: [
                Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: userProfile["profileImage"] != null
                        ? CustomImageWidget(
                            imageUrl: userProfile["profileImage"] as String,
                            width: 18.w,
                            height: 18.w,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            child: CustomIconWidget(
                              iconName: 'person',
                              size: 8.w,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: 'edit',
                      size: 3.w,
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile["name"] as String,
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  userProfile["email"] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color:
                        (userProfile["subscriptionType"] as String) == "Premium"
                            ? AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1)
                            : AppTheme.lightTheme.colorScheme.secondary
                                .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${userProfile["subscriptionType"]} Plan",
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: (userProfile["subscriptionType"] as String) ==
                              "Premium"
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if ((userProfile["subscriptionType"] as String) == "Free")
            GestureDetector(
              onTap: () {
                // Navigate to subscription upgrade
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Upgrade",
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
