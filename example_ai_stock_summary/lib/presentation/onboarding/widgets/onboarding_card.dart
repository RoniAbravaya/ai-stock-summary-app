import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OnboardingCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final bool isActive;

  const OnboardingCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90.w,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero illustration
          Container(
            width: 70.w,
            height: 30.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow
                      .withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomImageWidget(
                imageUrl: imageUrl,
                width: 70.w,
                height: 30.h,
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // Title
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 2.h),

          // Description
          Text(
            description,
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
