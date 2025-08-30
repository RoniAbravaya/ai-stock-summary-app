import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PasswordRequirementsWidget extends StatelessWidget {
  final String password;

  const PasswordRequirementsWidget({
    Key? key,
    required this.password,
  }) : super(key: key);

  bool _hasMinLength() => password.length >= 8;
  bool _hasUppercase() => password.contains(RegExp(r'[A-Z]'));
  bool _hasLowercase() => password.contains(RegExp(r'[a-z]'));
  bool _hasNumber() => password.contains(RegExp(r'[0-9]'));
  bool _hasSpecialChar() =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildRequirementItem(
            'At least 8 characters',
            _hasMinLength(),
          ),
          SizedBox(height: 1.h),
          _buildRequirementItem(
            'One uppercase letter',
            _hasUppercase(),
          ),
          SizedBox(height: 1.h),
          _buildRequirementItem(
            'One lowercase letter',
            _hasLowercase(),
          ),
          SizedBox(height: 1.h),
          _buildRequirementItem(
            'One number',
            _hasNumber(),
          ),
          SizedBox(height: 1.h),
          _buildRequirementItem(
            'One special character',
            _hasSpecialChar(),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String requirement, bool isValid) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: isValid ? 'check_circle' : 'radio_button_unchecked',
          size: 4.w,
          color: isValid
              ? AppTheme.lightTheme.colorScheme.tertiary
              : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            requirement,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: isValid
                  ? AppTheme.lightTheme.colorScheme.tertiary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
