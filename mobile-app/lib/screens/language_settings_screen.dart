import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/language_service.dart';
import '../config/app_config.dart';
 

/// Language Settings Screen
/// Allows users to select their preferred language from supported options
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final LanguageService _languageService = LanguageService();
  String _currentLanguage = 'en';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  void _loadCurrentLanguage() {
    setState(() {
      _currentLanguage = _languageService.currentLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_languageService.translate('settings_language')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildRedesignedList(),
    );
  }

  Widget _buildLanguageList() {
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
                      Icons.language,
                      color: Color(AppConfig.primaryBlue),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _languageService.translate('settings_language'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _languageService.translate('settings_language_desc'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Language Options Card
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.translate,
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available Languages',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...LanguageService.supportedLanguages.entries.map(
                (entry) => _buildLanguageOption(entry.key, entry.value),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Current Language Info
        _buildCurrentLanguageInfo(),
      ],
    );
  }

  Widget _buildRedesignedList() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header container
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.language, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _languageService.translate('settings_language'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _languageService.translate('settings_language_desc'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Options container
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.translate, color: Colors.grey.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Available Languages',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...LanguageService.supportedLanguages.entries.map(
                (entry) => _buildLanguageOption(entry.key, entry.value),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildCurrentLanguageInfo(),
      ],
    );
  }

  Widget _buildLanguageOption(String languageCode, String languageName) {
    final isSelected = _currentLanguage == languageCode;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Color(AppConfig.primaryBlue).withOpacity(0.1)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _getLanguageFlag(languageCode),
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        languageName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Color(AppConfig.primaryBlue) : null,
        ),
      ),
      subtitle: Text(
        _getLanguageSubtitle(languageCode),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check_circle, color: Color(AppConfig.primaryBlue))
              : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
      onTap: () => _changeLanguage(languageCode),
    );
  }

  Widget _buildCurrentLanguageInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(AppConfig.primaryBlue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(AppConfig.primaryBlue).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Color(AppConfig.primaryBlue),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Language',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(AppConfig.primaryBlue),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _languageService.getCurrentLanguageName(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(AppConfig.primaryBlue),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _getLanguageFlag(_currentLanguage),
            style: const TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      default:
        return '🌐';
    }
  }

  String _getLanguageSubtitle(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English (US)';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'Unknown';
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (languageCode == _currentLanguage) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _languageService.changeLanguage(languageCode);

      setState(() {
        _currentLanguage = languageCode;
        _isLoading = false;
      });

      // Show restart required dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text(_languageService.translate('restart_required')),
                content: Text(
                  _languageService.translate('restart_required_desc'),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      // Exit the app to force restart
                      SystemChannels.platform.invokeMethod(
                        'SystemNavigator.pop',
                      );
                    },
                    child: Text(_languageService.translate('restart_now')),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showErrorSnackBar('Error changing language: ${e.toString()}');
      }
    }
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
