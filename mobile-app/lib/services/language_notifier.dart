import 'package:flutter/material.dart';
import 'language_service.dart';

/// Language Change Notifier
/// Provides a way to notify the app when language changes
class LanguageNotifier extends ChangeNotifier {
  final LanguageService _languageService = LanguageService();

  String get currentLanguage => _languageService.currentLanguage;

  Future<void> changeLanguage(String languageCode) async {
    await _languageService.changeLanguage(languageCode);
    notifyListeners(); // This will trigger a rebuild of all listening widgets
  }

  String translate(String key, {String? fallback}) {
    return _languageService.translate(key, fallback: fallback);
  }

  String translateWithParams(
    String key,
    Map<String, String> params, {
    String? fallback,
  }) {
    return _languageService.translateWithParams(
      key,
      params,
      fallback: fallback,
    );
  }
}
