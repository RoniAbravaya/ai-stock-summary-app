import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TermsPrivacyWidget extends StatelessWidget {
  final bool isAccepted;
  final ValueChanged<bool?> onChanged;

  const TermsPrivacyWidget({
    Key? key,
    required this.isAccepted,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 6.w,
          height: 6.w,
          child: Checkbox(
            value: isAccepted,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: 'I agree to the ',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _showTermsDialog(context),
                    child: Text(
                      'Terms of Service',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: ' and ',
                  style: TextStyle(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _showPrivacyDialog(context),
                    child: Text(
                      'Privacy Policy',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Terms of Service'),
          content: SingleChildScrollView(
            child: Text(
              '''By using AI Stock Summary, you agree to these terms:

1. Service Usage
- Use the app for personal investment research only
- Do not share your account credentials
- Respect usage limits for free tier users

2. AI-Generated Content
- AI summaries are for informational purposes only
- Not financial advice or investment recommendations
- Always conduct your own research before investing

3. Data Privacy
- We protect your personal information
- Stock data is sourced from third-party providers
- Push notifications can be disabled in settings

4. Account Responsibilities
- Maintain accurate profile information
- Report any security issues immediately
- Comply with applicable laws and regulations

5. Limitations
- Service availability may vary
- We reserve the right to modify features
- Premium features require active subscription

For complete terms, visit our website.''',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Privacy Policy'),
          content: SingleChildScrollView(
            child: Text(
              '''AI Stock Summary Privacy Policy:

Information We Collect:
- Email address and profile information
- Stock watchlist and portfolio data
- App usage analytics and preferences
- Device information for push notifications

How We Use Your Data:
- Provide personalized stock summaries
- Send relevant market notifications
- Improve app features and performance
- Ensure account security

Data Sharing:
- We do not sell personal information
- Stock data from licensed providers
- Anonymous analytics for app improvement
- Legal compliance when required

Your Rights:
- Access and update your information
- Delete your account and data
- Control notification preferences
- Opt-out of analytics collection

Data Security:
- Encrypted data transmission
- Secure cloud storage
- Regular security audits
- Limited employee access

Contact us for privacy questions or data requests.''',
              style: AppTheme.lightTheme.textTheme.bodySmall,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
