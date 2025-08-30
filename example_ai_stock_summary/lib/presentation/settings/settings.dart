import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/notification_toggle_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/quiet_hours_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/settings_tile_widget.dart';
import './widgets/theme_selector_widget.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  // Mock user profile data
  final Map<String, dynamic> userProfile = {
    "id": "user_001",
    "name": "Sarah Johnson",
    "email": "sarah.johnson@email.com",
    "profileImage":
        "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face",
    "subscriptionType": "Free", // Free or Premium
    "joinDate": "2024-01-15",
    "aiSummariesUsed": 8,
    "aiSummariesLimit": 10,
  };

  // Notification preferences
  Map<String, bool> notificationSettings = {
    "priceAlerts": true,
    "aiSummaries": true,
    "newsUpdates": false,
    "marketing": false,
  };

  // App preferences
  String selectedTheme = "System";
  String selectedLanguage = "English";
  String selectedCurrency = "USD";
  bool biometricEnabled = false;
  bool cellularDataEnabled = true;
  bool autoRefreshEnabled = true;

  // Quiet hours
  TimeOfDay quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            size: 24,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 1.h),

            // Profile Header
            ProfileHeaderWidget(
              userProfile: userProfile,
              onEditProfile: _editProfile,
            ),

            // Account Section
            SettingsSectionWidget(
              title: "Account",
              children: [
                SettingsTileWidget(
                  title: "Personal Information",
                  subtitle: "Update your profile details",
                  iconName: 'person',
                  onTap: _editProfile,
                ),
                SettingsTileWidget(
                  title: "Subscription",
                  subtitle: userProfile["subscriptionType"] == "Premium"
                      ? "Manage your premium subscription"
                      : "Upgrade to premium for unlimited features",
                  iconName: 'star',
                  onTap: _manageSubscription,
                ),
                SettingsTileWidget(
                  title: "Usage Statistics",
                  subtitle:
                      "AI Summaries: ${userProfile["aiSummariesUsed"]}/${userProfile["aiSummariesLimit"]} used",
                  iconName: 'analytics',
                  onTap: _viewUsageStats,
                  showDivider: false,
                ),
              ],
            ),

            // Notifications Section
            SettingsSectionWidget(
              title: "Notifications",
              children: [
                NotificationToggleWidget(
                  title: "Price Alerts",
                  subtitle: "Get notified when stock prices hit your targets",
                  iconName: 'trending_up',
                  value: notificationSettings["priceAlerts"]!,
                  onChanged: (value) =>
                      _updateNotificationSetting("priceAlerts", value),
                ),
                Divider(
                  height: 1,
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.1),
                  indent: 4.w,
                  endIndent: 4.w,
                ),
                NotificationToggleWidget(
                  title: "AI Summary Alerts",
                  subtitle: "Notifications when new AI summaries are available",
                  iconName: 'psychology',
                  value: notificationSettings["aiSummaries"]!,
                  onChanged: (value) =>
                      _updateNotificationSetting("aiSummaries", value),
                ),
                Divider(
                  height: 1,
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.1),
                  indent: 4.w,
                  endIndent: 4.w,
                ),
                NotificationToggleWidget(
                  title: "News Updates",
                  subtitle: "Market news and financial updates",
                  iconName: 'newspaper',
                  value: notificationSettings["newsUpdates"]!,
                  onChanged: (value) =>
                      _updateNotificationSetting("newsUpdates", value),
                ),
                Divider(
                  height: 1,
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.1),
                  indent: 4.w,
                  endIndent: 4.w,
                ),
                NotificationToggleWidget(
                  title: "Marketing Communications",
                  subtitle: "Promotional offers and feature updates",
                  iconName: 'campaign',
                  value: notificationSettings["marketing"]!,
                  onChanged: (value) =>
                      _updateNotificationSetting("marketing", value),
                ),
              ],
            ),

            // Quiet Hours
            QuietHoursWidget(
              startTime: quietHoursStart,
              endTime: quietHoursEnd,
              onStartTimeChanged: (time) =>
                  setState(() => quietHoursStart = time),
              onEndTimeChanged: (time) => setState(() => quietHoursEnd = time),
            ),

            // Security Section
            SettingsSectionWidget(
              title: "Security",
              children: [
                SettingsTileWidget(
                  title: "Biometric Authentication",
                  subtitle: biometricEnabled
                      ? "Face ID/Fingerprint enabled"
                      : "Enable Face ID/Fingerprint",
                  iconName: 'fingerprint',
                  trailing: Switch(
                    value: biometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                ),
                SettingsTileWidget(
                  title: "App Lock",
                  subtitle: "Require authentication to open app",
                  iconName: 'lock',
                  onTap: _configureAppLock,
                ),
                SettingsTileWidget(
                  title: "Privacy Settings",
                  subtitle: "Manage your data and privacy preferences",
                  iconName: 'privacy_tip',
                  onTap: _managePrivacy,
                  showDivider: false,
                ),
              ],
            ),

            // Preferences Section
            SettingsSectionWidget(
              title: "Preferences",
              children: [
                SettingsTileWidget(
                  title: "Theme",
                  subtitle: "Choose your preferred app theme",
                  iconName: 'palette',
                  onTap: _showThemeSelector,
                ),
                SettingsTileWidget(
                  title: "Language",
                  subtitle: selectedLanguage,
                  iconName: 'language',
                  onTap: _selectLanguage,
                ),
                SettingsTileWidget(
                  title: "Currency",
                  subtitle: selectedCurrency,
                  iconName: 'attach_money',
                  onTap: _selectCurrency,
                ),
                SettingsTileWidget(
                  title: "Cellular Data",
                  subtitle: cellularDataEnabled
                      ? "Allow real-time updates"
                      : "Wi-Fi only",
                  iconName: 'signal_cellular_alt',
                  trailing: Switch(
                    value: cellularDataEnabled,
                    onChanged: (value) =>
                        setState(() => cellularDataEnabled = value),
                  ),
                ),
                SettingsTileWidget(
                  title: "Auto Refresh",
                  subtitle: autoRefreshEnabled
                      ? "Automatic data updates"
                      : "Manual refresh only",
                  iconName: 'refresh',
                  trailing: Switch(
                    value: autoRefreshEnabled,
                    onChanged: (value) =>
                        setState(() => autoRefreshEnabled = value),
                  ),
                  showDivider: false,
                ),
              ],
            ),

            // Data & Export Section
            SettingsSectionWidget(
              title: "Data & Export",
              children: [
                SettingsTileWidget(
                  title: "Export Portfolio Data",
                  subtitle: "Download your portfolio as CSV or PDF",
                  iconName: 'download',
                  onTap: _exportData,
                ),
                SettingsTileWidget(
                  title: "Clear Cache",
                  subtitle: "Free up storage space",
                  iconName: 'cleaning_services',
                  onTap: _clearCache,
                  showDivider: false,
                ),
              ],
            ),

            // Support Section
            SettingsSectionWidget(
              title: "Help & Support",
              children: [
                SettingsTileWidget(
                  title: "FAQ",
                  subtitle: "Frequently asked questions",
                  iconName: 'help',
                  onTap: _openFAQ,
                ),
                SettingsTileWidget(
                  title: "Contact Support",
                  subtitle: "Get help from our support team",
                  iconName: 'support_agent',
                  onTap: _contactSupport,
                ),
                SettingsTileWidget(
                  title: "Rate App",
                  subtitle: "Share your feedback on the app store",
                  iconName: 'star_rate',
                  onTap: _rateApp,
                ),
                SettingsTileWidget(
                  title: "About",
                  subtitle: "App version 1.2.3",
                  iconName: 'info',
                  onTap: _showAbout,
                  showDivider: false,
                ),
              ],
            ),

            // Logout Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: SettingsTileWidget(
                title: "Sign Out",
                subtitle: "Sign out of your account",
                iconName: 'logout',
                titleColor: AppTheme.lightTheme.colorScheme.error,
                onTap: _signOut,
                showDivider: false,
              ),
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                "Edit Profile",
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  children: [
                    // Profile photo section
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // Handle photo selection
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 25.w,
                            height: 25.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: userProfile["profileImage"] != null
                                  ? CustomImageWidget(
                                      imageUrl:
                                          userProfile["profileImage"] as String,
                                      width: 25.w,
                                      height: 25.w,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      child: CustomIconWidget(
                                        iconName: 'person',
                                        size: 12.w,
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      AppTheme.lightTheme.colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: CustomIconWidget(
                                iconName: 'camera_alt',
                                size: 4.w,
                                color:
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Tap to change profile photo",
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateNotificationSetting(String key, bool value) {
    setState(() {
      notificationSettings[key] = value;
    });
    HapticFeedback.lightImpact();
  }

  void _toggleBiometric(bool value) {
    setState(() {
      biometricEnabled = value;
    });
    HapticFeedback.lightImpact();
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                "Choose Theme",
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            ThemeSelectorWidget(
              selectedTheme: selectedTheme,
              onThemeChanged: (theme) {
                setState(() => selectedTheme = theme);
                Navigator.pop(context);
                HapticFeedback.lightImpact();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _manageSubscription() {
    Navigator.pushNamed(context, '/subscription');
  }

  void _viewUsageStats() {
    Navigator.pushNamed(context, '/usage-stats');
  }

  void _configureAppLock() {
    Navigator.pushNamed(context, '/app-lock');
  }

  void _managePrivacy() {
    Navigator.pushNamed(context, '/privacy');
  }

  void _selectLanguage() {
    // Show language selection dialog
  }

  void _selectCurrency() {
    // Show currency selection dialog
  }

  void _exportData() async {
    // Show export options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 30.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                "Export Portfolio Data",
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            SettingsTileWidget(
              title: "Export as CSV",
              subtitle: "Spreadsheet format for analysis",
              iconName: 'table_chart',
              onTap: () {
                Navigator.pop(context);
                _performExport('csv');
              },
            ),
            SettingsTileWidget(
              title: "Export as PDF",
              subtitle: "Formatted report for sharing",
              iconName: 'picture_as_pdf',
              onTap: () {
                Navigator.pop(context);
                _performExport('pdf');
              },
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }

  void _performExport(String format) {
    // Generate export data
    final portfolioData = """
Stock Symbol,Company Name,Shares,Purchase Price,Current Price,Gain/Loss
AAPL,Apple Inc.,10,\$150.00,\$175.50,+\$255.00
GOOGL,Alphabet Inc.,5,\$2800.00,\$2950.00,+\$750.00
MSFT,Microsoft Corp.,8,\$300.00,\$325.00,+\$200.00
TSLA,Tesla Inc.,3,\$800.00,\$750.00,-\$150.00
AMZN,Amazon.com Inc.,2,\$3200.00,\$3350.00,+\$300.00
""";

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Portfolio data exported as ${format.toUpperCase()}"),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Clear Cache",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          "This will clear all cached data including stock prices and AI summaries. You may need to reload data when you next use the app.",
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Cache cleared successfully"),
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                ),
              );
            },
            child: Text("Clear"),
          ),
        ],
      ),
    );
  }

  void _openFAQ() {
    Navigator.pushNamed(context, '/faq');
  }

  void _contactSupport() {
    Navigator.pushNamed(context, '/support');
  }

  void _rateApp() {
    // Open app store rating
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "About AI Stock Summary",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Version 1.2.3",
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              "AI-powered stock market analysis and portfolio tracking with real-time notifications.",
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Text(
              "© 2024 AI Stock Summary. All rights reserved.",
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Terms of Service"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Privacy Policy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Sign Out",
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          "Are you sure you want to sign out? You'll need to sign in again to access your portfolio and settings.",
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text(
              "Sign Out",
              style: TextStyle(color: AppTheme.lightTheme.colorScheme.onError),
            ),
          ),
        ],
      ),
    );
  }
}
