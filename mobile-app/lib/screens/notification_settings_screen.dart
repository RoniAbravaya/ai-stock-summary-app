import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/firebase_service.dart';
import '../services/language_service.dart';
import 'notification_history_screen.dart';

/// Notification Settings Screen
/// Allows users to manage notification preferences with a master toggle
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.firebaseEnabled,
    this.onLanguageChanged,
  });

  final bool firebaseEnabled;
  final VoidCallback? onLanguageChanged;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const String _notificationsEnabledKey = 'notifications_enabled';

  bool _notificationsEnabled = true;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
    // Force a rebuild after the first frame to ensure translations are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadNotificationPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading notification preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService().translate('settings_notifications')),
        backgroundColor: Color(AppConfig.primaryBlue),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildNotificationSettings(),
    );
  }

  Widget _buildNotificationSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Color(AppConfig.primaryBlue),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        LanguageService().translate('notif_settings_title'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  LanguageService().translate('notif_settings_desc'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Main Settings Card
        Card(
          child: Column(
            children: [
              // Master Notification Toggle
              _buildMasterToggle(),

              const Divider(height: 1),

              // Notification History Access
              _buildNotificationHistoryTile(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Information Card
        _buildInformationCard(),

        const SizedBox(height: 24),

        // Status Card
        _buildStatusCard(),
      ],
    );
  }

  Widget _buildMasterToggle() {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              _notificationsEnabled
                  ? Color(AppConfig.primaryGreen).withOpacity(0.1)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _notificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off,
          color:
              _notificationsEnabled
                  ? Color(AppConfig.primaryGreen)
                  : Colors.grey.shade600,
        ),
      ),
      title: Text(
        LanguageService().translate('notif_push_notifications'),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _notificationsEnabled
            ? LanguageService().translate('notif_receive_notifications')
            : LanguageService().translate('notif_all_disabled'),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing:
          _isSaving
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Switch(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeColor: Color(AppConfig.primaryGreen),
              ),
    );
  }

  Widget _buildNotificationHistoryTile() {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(AppConfig.primaryBlue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.history, color: Color(AppConfig.primaryBlue)),
      ),
      title: Text(
        LanguageService().translate('notif_history_title'),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        LanguageService().translate('notif_history_desc'),
        style: TextStyle(fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: _openNotificationHistory,
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LanguageService().translate('notif_about_title'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            LanguageService().translate('notif_about_content'),
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _notificationsEnabled
                ? Colors.green.shade50
                : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _notificationsEnabled
                  ? Colors.green.shade200
                  : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _notificationsEnabled ? Icons.check_circle : Icons.warning,
            color:
                _notificationsEnabled
                    ? Colors.green.shade600
                    : Colors.orange.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _notificationsEnabled
                      ? LanguageService().translate('notif_status_active')
                      : LanguageService().translate('notif_status_disabled'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        _notificationsEnabled
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _notificationsEnabled
                      ? LanguageService().translate('notif_status_active_desc')
                      : LanguageService().translate(
                        'notif_status_disabled_desc',
                      ),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _notificationsEnabled
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, value);

      // Update FCM token registration based on preference
      if (widget.firebaseEnabled) {
        await _updateFCMRegistration(value);
      }

      setState(() {
        _notificationsEnabled = value;
        _isSaving = false;
      });

      _showSuccessSnackBar(
        value
            ? LanguageService().translate('notif_enabled_success')
            : LanguageService().translate('notif_disabled_success'),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      _showErrorSnackBar(
        LanguageService().translateWithParams('notif_error_updating', {
          'error': e.toString(),
        }),
      );
    }
  }

  Future<void> _updateFCMRegistration(bool enabled) async {
    try {
      if (enabled) {
        // Re-register for notifications by refreshing token
        await FirebaseService().refreshFCMToken();
      }
      // Note: We don't unregister the token when disabled, just store the preference
      // This allows easy re-enabling without requiring permission again
    } catch (e) {
      print('Error updating FCM registration: $e');
    }
  }

  void _openNotificationHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => NotificationHistoryScreen(
              firebaseEnabled: widget.firebaseEnabled,
            ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(AppConfig.primaryGreen),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(AppConfig.primaryRed),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
